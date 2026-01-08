use std::fs::File;
use std::os::unix::io::AsRawFd;
use std::thread;

pub enum TouchEvent {
    Start(f64, f64),
    Move(f64, f64),
    End(f64, f64),
}

pub struct TouchMonitor {
    _handle: thread::JoinHandle<()>,
}

impl TouchMonitor {
    pub fn new<F>(callback: F) -> Self
    where
        F: Fn(TouchEvent) + Send + 'static,
    {
        let handle = thread::spawn(move || {
            if let Err(e) = monitor_touch(callback) {
                eprintln!("Touch monitor error: {}", e);
            }
        });

        TouchMonitor { _handle: handle }
    }
}

fn find_touchscreen() -> Option<String> {
    // Look for touchscreen device
    for i in 0..20 {
        let path = format!("/dev/input/event{}", i);
        if let Ok(_file) = File::open(&path) {
            // Check if it's a touchscreen by reading capabilities
            // For now, just try common touchscreen device numbers
            if let Ok(name) = std::fs::read_to_string(format!("/sys/class/input/event{}/device/name", i)) {
                let name = name.trim().to_lowercase();
                if name.contains("touch") || name.contains("ts") || name.contains("fts") {
                    return Some(path);
                }
            }
        }
    }
    // Fallback to event3 which is common for touchscreens
    Some("/dev/input/event3".to_string())
}

fn monitor_touch<F>(callback: F) -> Result<(), Box<dyn std::error::Error>>
where
    F: Fn(TouchEvent),
{
    let device_path = find_touchscreen().ok_or("No touchscreen found")?;
    println!("Touch monitor using: {}", device_path);

    let file = File::open(&device_path)?;
    let fd = file.as_raw_fd();

    // Get screen dimensions from touchscreen
    let mut abs_x_max: i32 = 1080;
    let mut abs_y_max: i32 = 2340;

    // Try to read absinfo
    unsafe {
        let mut absinfo: libc::input_absinfo = std::mem::zeroed();
        // ABS_MT_POSITION_X = 0x35
        if libc::ioctl(fd, 0x40184540u64 + 0x35, &mut absinfo) == 0 {
            abs_x_max = absinfo.maximum;
        }
        // ABS_MT_POSITION_Y = 0x36
        if libc::ioctl(fd, 0x40184540u64 + 0x36, &mut absinfo) == 0 {
            abs_y_max = absinfo.maximum;
        }
    }

    println!("Touch range: {}x{}", abs_x_max, abs_y_max);

    // GTK uses logical coordinates with 2x scaling on HiDPI
    // Touch device reports physical coords, divide by scale factor
    let scale_factor = 2.0;
    let screen_w = abs_x_max as f64 / scale_factor;
    let screen_h = abs_y_max as f64 / scale_factor;
    println!("Using screen dimensions: {}x{} (scale {})", screen_w, screen_h, scale_factor);

    let mut current_slot = 0i32;
    let mut slot_x: [i32; 10] = [0; 10];
    let mut slot_y: [i32; 10] = [0; 10];
    let mut slot_tracking: [i32; 10] = [-1; 10];

    let mut buf = [0u8; 24]; // sizeof(input_event)

    loop {
        use std::io::Read;
        let mut file_ref = &file;
        if file_ref.read_exact(&mut buf).is_err() {
            break;
        }

        // Parse input_event struct
        let ev_type = u16::from_ne_bytes([buf[16], buf[17]]);
        let ev_code = u16::from_ne_bytes([buf[18], buf[19]]);
        let ev_value = i32::from_ne_bytes([buf[20], buf[21], buf[22], buf[23]]);

        const EV_ABS: u16 = 3;
        const ABS_MT_SLOT: u16 = 0x2f;
        const ABS_MT_TRACKING_ID: u16 = 0x39;
        const ABS_MT_POSITION_X: u16 = 0x35;
        const ABS_MT_POSITION_Y: u16 = 0x36;

        if ev_type == EV_ABS {
            match ev_code {
                ABS_MT_SLOT => {
                    current_slot = ev_value.min(9).max(0);
                }
                ABS_MT_TRACKING_ID => {
                    let slot = current_slot as usize;
                    if ev_value == -1 {
                        // Touch ended
                        if slot_tracking[slot] != -1 {
                            let x = (slot_x[slot] as f64 / abs_x_max as f64) * screen_w;
                            let y = (slot_y[slot] as f64 / abs_y_max as f64) * screen_h;
                            callback(TouchEvent::End(x, y));
                            slot_tracking[slot] = -1;
                        }
                    } else {
                        // Touch started
                        slot_tracking[slot] = ev_value;
                        let x = (slot_x[slot] as f64 / abs_x_max as f64) * screen_w;
                        let y = (slot_y[slot] as f64 / abs_y_max as f64) * screen_h;
                        callback(TouchEvent::Start(x, y));
                    }
                }
                ABS_MT_POSITION_X => {
                    let slot = current_slot as usize;
                    slot_x[slot] = ev_value;
                    if slot_tracking[slot] != -1 {
                        let x = (slot_x[slot] as f64 / abs_x_max as f64) * screen_w;
                        let y = (slot_y[slot] as f64 / abs_y_max as f64) * screen_h;
                        callback(TouchEvent::Move(x, y));
                    }
                }
                ABS_MT_POSITION_Y => {
                    let slot = current_slot as usize;
                    slot_y[slot] = ev_value;
                    if slot_tracking[slot] != -1 {
                        let x = (slot_x[slot] as f64 / abs_x_max as f64) * screen_w;
                        let y = (slot_y[slot] as f64 / abs_y_max as f64) * screen_h;
                        callback(TouchEvent::Move(x, y));
                    }
                }
                _ => {}
            }
        }
    }

    Ok(())
}
