use std::sync::{Arc, Mutex, atomic::{AtomicBool, Ordering}};
use std::time::Instant;

/// Simple screen analysis at low framerate (2fps max)
/// Just captures brightness data for effect calculations
pub struct ScreenAnalyzer {
    data: Arc<Mutex<Option<AnalysisData>>>,
    busy: Arc<AtomicBool>,
    last_capture: Arc<Mutex<Instant>>,
}

#[derive(Clone)]
pub struct AnalysisData {
    /// Average brightness 0.0-1.0 in 8x8 grid cells
    pub brightness_grid: [[f32; 8]; 8],
    /// Overall screen brightness
    pub avg_brightness: f32,
    /// Screen dimensions
    pub width: u32,
    pub height: u32,
    pub timestamp: Instant,
}

impl ScreenAnalyzer {
    pub fn new() -> Self {
        Self {
            data: Arc::new(Mutex::new(None)),
            busy: Arc::new(AtomicBool::new(false)),
            last_capture: Arc::new(Mutex::new(Instant::now() - std::time::Duration::from_secs(10))),
        }
    }

    /// Request analysis update (max 2fps)
    pub fn request_update(&self) {
        // Rate limit to 2fps
        {
            let last = self.last_capture.lock().unwrap();
            if last.elapsed().as_millis() < 500 {
                return;
            }
        }

        if self.busy.swap(true, Ordering::SeqCst) {
            return;
        }

        let data = self.data.clone();
        let busy = self.busy.clone();
        let last_capture = self.last_capture.clone();

        std::thread::spawn(move || {
            if let Some(analysis) = do_capture_analysis() {
                *data.lock().unwrap() = Some(analysis);
                *last_capture.lock().unwrap() = Instant::now();
            }
            busy.store(false, Ordering::SeqCst);
        });
    }

    pub fn get_data(&self) -> Option<AnalysisData> {
        self.data.lock().unwrap().clone()
    }

    /// Get brightness at normalized screen position (0-1, 0-1)
    pub fn brightness_at(&self, nx: f32, ny: f32) -> f32 {
        if let Some(ref data) = *self.data.lock().unwrap() {
            let gx = ((nx * 8.0) as usize).min(7);
            let gy = ((ny * 8.0) as usize).min(7);
            return data.brightness_grid[gy][gx];
        }
        0.5 // Default mid brightness
    }
}

fn do_capture_analysis() -> Option<AnalysisData> {
    // Use grim for quick capture - just need rough brightness data
    let output = std::process::Command::new("grim")
        .args(["-t", "ppm", "-s", "0.125", "-"]) // 1/8 scale for speed
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    parse_ppm_brightness(&output.stdout)
}

fn parse_ppm_brightness(data: &[u8]) -> Option<AnalysisData> {
    // Parse PPM header
    let mut pos = 0;

    // Skip P6 magic
    while pos < data.len() && data[pos] != b'\n' { pos += 1; }
    pos += 1;

    // Skip comments
    while pos < data.len() && data[pos] == b'#' {
        while pos < data.len() && data[pos] != b'\n' { pos += 1; }
        pos += 1;
    }

    // Parse width
    let mut width_str = String::new();
    while pos < data.len() && data[pos] != b' ' && data[pos] != b'\n' {
        width_str.push(data[pos] as char);
        pos += 1;
    }
    pos += 1;

    // Parse height
    let mut height_str = String::new();
    while pos < data.len() && data[pos] != b' ' && data[pos] != b'\n' {
        height_str.push(data[pos] as char);
        pos += 1;
    }
    pos += 1;

    // Skip max value line
    while pos < data.len() && data[pos] != b'\n' { pos += 1; }
    pos += 1;

    let width: u32 = width_str.parse().ok()?;
    let height: u32 = height_str.parse().ok()?;

    let pixels = &data[pos..];

    // Calculate 8x8 brightness grid
    let mut brightness_grid = [[0.0f32; 8]; 8];
    let mut counts = [[0u32; 8]; 8];
    let mut total_brightness = 0.0f32;
    let mut total_count = 0u32;

    let cell_w = width / 8;
    let cell_h = height / 8;

    for y in 0..height {
        for x in 0..width {
            let idx = ((y * width + x) * 3) as usize;
            if idx + 2 >= pixels.len() { break; }

            let r = pixels[idx] as f32 / 255.0;
            let g = pixels[idx + 1] as f32 / 255.0;
            let b = pixels[idx + 2] as f32 / 255.0;

            // Perceived brightness
            let brightness = 0.299 * r + 0.587 * g + 0.114 * b;

            let gx = ((x / cell_w) as usize).min(7);
            let gy = ((y / cell_h) as usize).min(7);

            brightness_grid[gy][gx] += brightness;
            counts[gy][gx] += 1;
            total_brightness += brightness;
            total_count += 1;
        }
    }

    // Average each cell
    for y in 0..8 {
        for x in 0..8 {
            if counts[y][x] > 0 {
                brightness_grid[y][x] /= counts[y][x] as f32;
            }
        }
    }

    let avg_brightness = if total_count > 0 {
        total_brightness / total_count as f32
    } else {
        0.5
    };

    Some(AnalysisData {
        brightness_grid,
        avg_brightness,
        width: width * 8, // Original size
        height: height * 8,
        timestamp: Instant::now(),
    })
}
