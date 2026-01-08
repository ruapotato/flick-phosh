use gtk4::prelude::*;
use gtk4::{Application, ApplicationWindow, DrawingArea};
use gtk4_layer_shell::{Edge, Layer, LayerShell};
use gdk4::prelude::SurfaceExt;
use glib::ControlFlow;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::mpsc;
use std::time::Instant;
use std::f64::consts::PI;
use rand::Rng;

mod touch;
mod config;
mod capture;

use touch::TouchMonitor;
use config::Config;

// ============ FIRE PARTICLE ============

#[derive(Clone)]
struct FireParticle {
    x: f64,
    y: f64,
    vx: f64,
    vy: f64,
    life: f64,
    max_life: f64,
    size: f64,
    heat: f64,
    wobble: f64,
}

// ============ FIRE EFFECT ============

struct FireEffect {
    x: f64,
    y: f64,
    particles: Vec<FireParticle>,
    is_active: bool,
    intensity: f64,
    start_time: Instant,
}

impl FireEffect {
    fn new(x: f64, y: f64) -> Self {
        Self {
            x, y,
            particles: Vec::with_capacity(150),
            is_active: true,
            intensity: 0.0,
            start_time: Instant::now(),
        }
    }

    fn spawn_particles(&mut self, dt: f64) {
        if !self.is_active { return; }
        if self.particles.len() > 50 { return; }

        let mut rng = rand::thread_rng();
        self.intensity = (self.start_time.elapsed().as_secs_f64() * 8.0).min(1.0);
        let spawn_count = (15.0 * self.intensity * dt * 60.0) as i32;

        for _ in 0..spawn_count {
            let spread = 25.0 * self.intensity;
            let offset_x = (rng.gen::<f64>() - 0.5) * spread;
            let offset_y = (rng.gen::<f64>() - 0.5) * spread * 0.5;
            let speed = rng.gen::<f64>() * 250.0 + 150.0;
            let angle = -PI/2.0 + (rng.gen::<f64>() - 0.5) * 0.8;
            let heat = rng.gen::<f64>() * 0.3 + 0.7;
            let max_life = rng.gen::<f64>() * 0.6 + 0.3;

            self.particles.push(FireParticle {
                x: self.x + offset_x,
                y: self.y + offset_y,
                vx: angle.cos() * speed * 0.3,
                vy: angle.sin() * speed,
                life: 1.0,
                max_life,
                size: rng.gen::<f64>() * 15.0 + 8.0,
                heat,
                wobble: rng.gen::<f64>() * PI * 2.0,
            });

            // Sparks
            if rng.gen::<f64>() < 0.1 * self.intensity {
                let spark_angle = -PI/2.0 + (rng.gen::<f64>() - 0.5) * 1.5;
                let spark_speed = rng.gen::<f64>() * 300.0 + 150.0;
                self.particles.push(FireParticle {
                    x: self.x + (rng.gen::<f64>() - 0.5) * 20.0,
                    y: self.y,
                    vx: spark_angle.cos() * spark_speed,
                    vy: spark_angle.sin() * spark_speed,
                    life: 1.0,
                    max_life: rng.gen::<f64>() * 0.3 + 0.1,
                    size: rng.gen::<f64>() * 3.0 + 1.0,
                    heat: 1.0,
                    wobble: rng.gen::<f64>() * PI * 2.0,
                });
            }
        }
    }

    fn update(&mut self, dt: f64, time: f64) {
        let mut rng = rand::thread_rng();

        for p in &mut self.particles {
            let turb_x = (p.wobble + time * 8.0).sin() * 30.0 * (1.0 - p.life);
            let turb_y = (p.wobble * 1.3 + time * 6.0).cos() * 15.0;

            p.x += (p.vx + turb_x) * dt;
            p.y += (p.vy + turb_y) * dt;
            p.vx *= 0.98;
            p.vy -= 80.0 * dt;
            p.vx += (rng.gen::<f64>() - 0.5) * 100.0 * dt;
            p.life -= dt / p.max_life;
            p.heat = (p.heat - dt * 0.8).max(0.0);

            let life_phase = 1.0 - p.life;
            if life_phase < 0.2 {
                p.size *= 1.0 + dt * 2.0;
            } else {
                p.size *= 1.0 - dt * 0.5;
            }
        }

        self.particles.retain(|p| p.life > 0.0 && p.size > 0.5);

        if !self.is_active {
            self.intensity = (self.intensity - dt * 3.0).max(0.0);
        }
    }

    fn is_done(&self) -> bool {
        !self.is_active && self.particles.is_empty()
    }
}

// ============ LIVING PIXELS ============

#[derive(Clone)]
struct LivingPixel {
    x: f64,
    y: f64,
    vx: f64,
    vy: f64,
    life: f64,
    kind: LivingKind,
    phase: f64,
}

#[derive(Clone, Copy)]
enum LivingKind {
    Star,
    ShootingStar,
    Firefly,
}

// ============ STATE ============

struct EffectsState {
    fires: Vec<FireEffect>,
    living_pixels: Vec<LivingPixel>,
    last_spawn: Instant,
    config: Config,
    width: i32,
    height: i32,
    time: f64,
}

impl EffectsState {
    fn new() -> Self {
        Self {
            fires: Vec::new(),
            living_pixels: Vec::new(),
            last_spawn: Instant::now(),
            config: Config::load(),
            width: 540,
            height: 1170,
            time: 0.0,
        }
    }

    fn add_touch(&mut self, x: f64, y: f64) {
        if self.config.fire_touch_enabled {
            self.fires.push(FireEffect::new(x, y));
        }
    }

    fn update_touch(&mut self, x: f64, y: f64) {
        for fire in &mut self.fires {
            if fire.is_active {
                fire.x = x;
                fire.y = y;
                break;
            }
        }
    }

    fn end_touch(&mut self, _x: f64, _y: f64) {
        for fire in &mut self.fires {
            if fire.is_active {
                fire.is_active = false;
                break;
            }
        }
    }

    fn tick(&mut self, dt: f64) {
        self.time += dt;

        // Update fires
        for fire in &mut self.fires {
            fire.spawn_particles(dt);
            fire.update(dt, self.time);
        }
        self.fires.retain(|f| !f.is_done());

        // Living pixels
        if self.config.living_pixels_enabled {
            self.update_living_pixels(dt);

            if self.last_spawn.elapsed().as_millis() > 100 {
                self.spawn_living_pixels();
                self.last_spawn = Instant::now();
            }

            self.living_pixels.retain(|p| p.life > 0.0);
        }
    }

    fn update_living_pixels(&mut self, dt: f64) {
        let w = self.width as f64;
        let h = self.height as f64;

        for pixel in &mut self.living_pixels {
            pixel.phase += dt * 5.0;

            match pixel.kind {
                LivingKind::Star => {
                    pixel.life -= dt * 0.05;
                }
                LivingKind::ShootingStar => {
                    pixel.x += pixel.vx * dt;
                    pixel.y += pixel.vy * dt;
                    pixel.life -= dt * 0.4;
                }
                LivingKind::Firefly => {
                    pixel.vx += (rand::random::<f64>() - 0.5) * 100.0 * dt;
                    pixel.vy += (rand::random::<f64>() - 0.5) * 100.0 * dt;
                    pixel.vx *= 0.95;
                    pixel.vy *= 0.95;
                    pixel.x += pixel.vx * dt;
                    pixel.y += pixel.vy * dt;
                    pixel.life -= dt * 0.15;

                    if pixel.x < 0.0 { pixel.x = 0.0; pixel.vx = pixel.vx.abs(); }
                    if pixel.x > w { pixel.x = w; pixel.vx = -pixel.vx.abs(); }
                    if pixel.y < 0.0 { pixel.y = 0.0; pixel.vy = pixel.vy.abs(); }
                    if pixel.y > h { pixel.y = h; pixel.vy = -pixel.vy.abs(); }
                }
            }
        }
    }

    fn spawn_living_pixels(&mut self) {
        if self.living_pixels.len() > 100 { return; }

        let mut rng = rand::thread_rng();
        let w = self.width as f64;
        let h = self.height as f64;

        // Stars
        if self.config.lp_stars && rng.gen::<f64>() < 0.3 {
            self.living_pixels.push(LivingPixel {
                x: rng.gen::<f64>() * w,
                y: rng.gen::<f64>() * h * 0.6,
                vx: 0.0, vy: 0.0,
                life: 1.0,
                kind: LivingKind::Star,
                phase: rng.gen::<f64>() * PI * 2.0,
            });
        }

        // Shooting stars
        if self.config.lp_shooting_stars && rng.gen::<f64>() < 0.02 {
            self.living_pixels.push(LivingPixel {
                x: rng.gen::<f64>() * w * 0.5,
                y: rng.gen::<f64>() * h * 0.3,
                vx: rng.gen::<f64>() * 400.0 + 200.0,
                vy: rng.gen::<f64>() * 200.0 + 100.0,
                life: 1.0,
                kind: LivingKind::ShootingStar,
                phase: 0.0,
            });
        }

        // Fireflies
        if self.config.lp_fireflies && rng.gen::<f64>() < 0.08 {
            self.living_pixels.push(LivingPixel {
                x: rng.gen::<f64>() * w,
                y: rng.gen::<f64>() * h,
                vx: (rng.gen::<f64>() - 0.5) * 30.0,
                vy: (rng.gen::<f64>() - 0.5) * 30.0,
                life: 1.0,
                kind: LivingKind::Firefly,
                phase: rng.gen::<f64>() * PI * 2.0,
            });
        }
    }
}

// ============ DRAWING ============

fn draw_effects(cr: &gtk4::cairo::Context, state: &EffectsState) {
    cr.set_operator(gtk4::cairo::Operator::Source);
    cr.set_source_rgba(0.0, 0.0, 0.0, 0.0);
    cr.paint().ok();
    cr.set_operator(gtk4::cairo::Operator::Over);

    // Draw living pixels
    draw_living_pixels(cr, &state.living_pixels, state.time);

    // Draw fires
    for fire in &state.fires {
        draw_fire(cr, fire);
    }
}

fn draw_fire(cr: &gtk4::cairo::Context, fire: &FireEffect) {
    for p in &fire.particles {
        let alpha = (p.life * 1.5).min(1.0);
        let (r, g, b, _) = heat_to_color(p.heat, alpha);
        cr.set_source_rgba(r, g, b, alpha * 0.9);
        cr.arc(p.x, p.y, p.size, 0.0, 2.0 * PI);
        cr.fill().ok();
    }

    if fire.is_active && fire.intensity > 0.3 {
        cr.set_source_rgba(1.0, 0.5, 0.1, 0.2 * fire.intensity);
        cr.arc(fire.x, fire.y, 30.0 * fire.intensity, 0.0, 2.0 * PI);
        cr.fill().ok();
    }
}

fn heat_to_color(heat: f64, alpha: f64) -> (f64, f64, f64, f64) {
    if heat > 0.9 {
        (1.0, 1.0, 0.9, alpha)
    } else if heat > 0.7 {
        let t = (heat - 0.7) / 0.2;
        (1.0, 0.9 + t * 0.1, 0.3 + t * 0.6, alpha)
    } else if heat > 0.5 {
        let t = (heat - 0.5) / 0.2;
        (1.0, 0.5 + t * 0.4, 0.1 + t * 0.2, alpha)
    } else if heat > 0.3 {
        let t = (heat - 0.3) / 0.2;
        (0.9 + t * 0.1, 0.2 + t * 0.3, 0.05 + t * 0.05, alpha)
    } else if heat > 0.1 {
        let t = (heat - 0.1) / 0.2;
        (0.5 + t * 0.4, 0.05 + t * 0.15, 0.02 + t * 0.03, alpha * (0.5 + t * 0.5))
    } else {
        (0.2, 0.2, 0.2, alpha * 0.3)
    }
}

fn draw_living_pixels(cr: &gtk4::cairo::Context, pixels: &[LivingPixel], time: f64) {
    for p in pixels {
        let alpha = p.life.min(1.0);

        match p.kind {
            LivingKind::Star => {
                let twinkle = 0.5 + 0.5 * (p.phase + time * 3.0).sin();
                cr.set_source_rgba(1.0, 1.0, 0.95, alpha * twinkle * 0.9);
                cr.arc(p.x, p.y, 1.5, 0.0, 2.0 * PI);
                cr.fill().ok();

                if twinkle > 0.7 {
                    cr.set_source_rgba(1.0, 1.0, 1.0, alpha * (twinkle - 0.7) * 2.0);
                    cr.set_line_width(0.5);
                    let len = 4.0 * twinkle;
                    cr.move_to(p.x - len, p.y);
                    cr.line_to(p.x + len, p.y);
                    cr.move_to(p.x, p.y - len);
                    cr.line_to(p.x, p.y + len);
                    cr.stroke().ok();
                }
            }
            LivingKind::ShootingStar => {
                for i in 0..8 {
                    let t = i as f64 / 8.0;
                    let tx = p.x - p.vx * 0.02 * t;
                    let ty = p.y - p.vy * 0.02 * t;
                    let ta = alpha * (1.0 - t) * 0.8;
                    cr.set_source_rgba(1.0, 1.0, 0.9, ta);
                    cr.arc(tx, ty, 2.0 * (1.0 - t * 0.5), 0.0, 2.0 * PI);
                    cr.fill().ok();
                }
                cr.set_source_rgba(1.0, 1.0, 1.0, alpha);
                cr.arc(p.x, p.y, 2.5, 0.0, 2.0 * PI);
                cr.fill().ok();
            }
            LivingKind::Firefly => {
                let glow = 0.5 + 0.5 * (p.phase + time * 4.0).sin();
                cr.set_source_rgba(0.7, 1.0, 0.3, alpha * glow * 0.4);
                cr.arc(p.x, p.y, 8.0, 0.0, 2.0 * PI);
                cr.fill().ok();
                cr.set_source_rgba(0.9, 1.0, 0.5, alpha * glow);
                cr.arc(p.x, p.y, 2.0, 0.0, 2.0 * PI);
                cr.fill().ok();
            }
        }
    }
}

// ============ MAIN ============

fn main() {
    let app = Application::builder()
        .application_id("org.flick.Effects")
        .build();

    app.connect_activate(|app| {
        let window = ApplicationWindow::builder()
            .application(app)
            .title("Flick Effects")
            .build();

        let css_provider = gtk4::CssProvider::new();
        css_provider.load_from_data("window { background-color: transparent; }");
        gtk4::style_context_add_provider_for_display(
            &gdk4::Display::default().unwrap(),
            &css_provider,
            gtk4::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );

        window.init_layer_shell();
        window.set_layer(Layer::Overlay);
        window.set_anchor(Edge::Top, true);
        window.set_anchor(Edge::Bottom, true);
        window.set_anchor(Edge::Left, true);
        window.set_anchor(Edge::Right, true);
        window.set_exclusive_zone(-1);
        window.set_keyboard_mode(gtk4_layer_shell::KeyboardMode::None);

        let window_weak = window.downgrade();
        window.connect_realize(move |_| {
            if let Some(win) = window_weak.upgrade() {
                let surface = win.surface();
                let region = gdk4::cairo::Region::create();
                surface.set_input_region(&region);
            }
        });

        let drawing_area = DrawingArea::new();

        let da_css = gtk4::CssProvider::new();
        da_css.load_from_data(".transparent { background-color: transparent; }");
        drawing_area.set_css_classes(&["transparent"]);
        gtk4::style_context_add_provider_for_display(
            &gdk4::Display::default().unwrap(),
            &da_css,
            gtk4::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );

        window.set_child(Some(&drawing_area));

        let state = Rc::new(RefCell::new(EffectsState::new()));
        let state_draw = state.clone();
        let state_tick = state.clone();
        let state_events = state.clone();

        let (tx, rx) = mpsc::channel::<touch::TouchEvent>();

        let _touch_monitor = TouchMonitor::new(move |event| {
            let _ = tx.send(event);
        });

        glib::timeout_add_local(std::time::Duration::from_millis(8), move || {
            while let Ok(event) = rx.try_recv() {
                let mut state = state_events.borrow_mut();
                match event {
                    touch::TouchEvent::Start(x, y) => state.add_touch(x, y),
                    touch::TouchEvent::Move(x, y) => state.update_touch(x, y),
                    touch::TouchEvent::End(x, y) => state.end_touch(x, y),
                }
            }
            ControlFlow::Continue
        });

        drawing_area.set_draw_func(move |_, cr, w, h| {
            let mut state = state_draw.borrow_mut();
            state.width = w;
            state.height = h;
            draw_effects(cr, &state);
        });

        let last_tick = Rc::new(RefCell::new(Instant::now()));
        glib::timeout_add_local(std::time::Duration::from_millis(25), move || {
            let dt = last_tick.borrow().elapsed().as_secs_f64();
            *last_tick.borrow_mut() = Instant::now();

            state_tick.borrow_mut().tick(dt);
            drawing_area.queue_draw();
            ControlFlow::Continue
        });

        window.present();
    });

    app.run();
}
