use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Clone, Serialize, Deserialize)]
pub struct Config {
    // Fire effect on touch
    #[serde(default = "default_true")]
    pub fire_touch_enabled: bool,

    // Living pixels - ambient effects
    #[serde(default)]
    pub living_pixels_enabled: bool,
    #[serde(default = "default_true")]
    pub lp_stars: bool,
    #[serde(default = "default_true")]
    pub lp_shooting_stars: bool,
    #[serde(default = "default_true")]
    pub lp_fireflies: bool,
}

fn default_true() -> bool { true }

impl Default for Config {
    fn default() -> Self {
        Self {
            fire_touch_enabled: true,
            living_pixels_enabled: false,
            lp_stars: true,
            lp_shooting_stars: true,
            lp_fireflies: true,
        }
    }
}

impl Config {
    pub fn config_path() -> PathBuf {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/root".to_string());
        PathBuf::from(home)
            .join(".local")
            .join("state")
            .join("flick")
            .join("effects_config.json")
    }

    pub fn load() -> Self {
        let path = Self::config_path();
        if let Ok(content) = fs::read_to_string(&path) {
            if let Ok(config) = serde_json::from_str(&content) {
                println!("Loaded config from {:?}", path);
                return config;
            }
        }
        println!("Using default config");
        Self::default()
    }
}
