use regex::Regex;
use serde::{Serialize, Deserialize};
use std::error::Error;
use std::fs::File;
use std::fs;
use std::io::BufRead;
use std::io::BufReader;
use std::path::Path;
use std::process::Command;

#[derive(Deserialize, Debug)]
struct Cfg {
    iptables_bin: String,
    iptables_cfg_folder: String,
    iptables_cfg_file_v4: String,
    log_folders: Vec<String>,
    patterns: Vec<String>
}
#[derive(Serialize, Deserialize, Debug)]
struct Ips {
    blacklist: Vec<String>,
    whitelist: Vec<String>
}

static mut PATTERNS: Vec<String> = vec![];

fn main() {
    println!("Janus 0.0.1");

    // Load the config.
    let mut cfg: Cfg = load_cfg("cfg.json").unwrap();
    // Load the ips.
    let mut ips: Ips = load_ips("ips.json").unwrap();

    // Process the patterns.
    for file in cfg.patterns.iter() {
        let to_join: Vec<String> = vec!["./patterns/".to_string(), file.to_string(), ".json".to_string()];
        let joined: String = to_join.join("");
        load_patterns(joined);
    }

    // Process the logs in the log folders
    for file in cfg.log_folders.iter() {
        match process_logs(file.to_string(), &mut ips) {
            Ok(_) => println!("Processed {}", file),
            Err(e) => println!("Error processing the folder, {}, {}", file, e)
        }
    }

    write_ips("ips.json".to_string(), &mut ips);
    setup_iptables(&mut ips, &mut cfg);
}

/**
 * Load the cfg.json.
 */
fn load_cfg<P: AsRef<Path>>(path: P) -> Result<Cfg, Box<dyn Error>> {
    println!("Loading CFG JSON");

    let file = File::open(path).expect("Failed to load the CFG JSON");
    let reader = BufReader::new(file);

    let cfg = serde_json::from_reader(reader)?;
    Ok(cfg)
}

/**
 * Load the ips.json.
 */
fn load_ips<P: AsRef<Path>>(path: P) -> Result<Ips, Box<dyn Error>> {
    println!("Loading IPs JSON");

    let file = File::open(path).expect("Failed to load the IPs JSON");
    let reader = BufReader::new(file);

    let ips = serde_json::from_reader(reader)?;
    Ok(ips)
}

/**
 * Load the various patterns to match against the log enteries.
 */
fn load_patterns(path: String) {
    println!("Loading Patterns JSON, {}", path);

    let file = File::open(path).expect("Failed to load the Patterns JSON");
    let reader = BufReader::new(file);

    unsafe {
        let json: Vec<String> = serde_json::from_reader(reader).expect("Failed to process the pattern file");
        for pattern in json.iter() {
            PATTERNS.push(pattern.to_string());
        }
    }
}

/**
 * Process the logs.
 */
fn process_logs(path: String, ips: &mut Ips) -> Result<(), Box<dyn Error>> {
    println!("Reading {}", path);
    let files = fs::read_dir(path)?;
    
    for file in files {
        let log: String = file.unwrap().path().display().to_string();
        if log.contains(".gz") {
            continue;
        }

        let log: File = File::open(log)?;
        for line in BufReader::new(log).lines() {
            let search: String = line.unwrap();
            unsafe {
                for pattern in PATTERNS.iter() {
                    if search.contains(&pattern.to_lowercase()) {
                        let re: Regex = Regex::new(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}").unwrap();
                        let search: &str = &search;
                        for ip in re.find_iter(search) {
                            let str_ip = &String::from(ip.as_str());
                            if ip.as_str() != "127.0.0.1" && !ips.blacklist.contains(str_ip) && !ips.whitelist.contains(str_ip) {
                                ips.blacklist.push(str_ip.to_owned());
                                println!("Found {}, blacklisting for pattern {}", ip.as_str(), pattern);
                            }
                        }
                    }
                }
            }
        }
    }

    Ok(())
}

/**
 * Setup iptables to block the IPs.
 */
fn setup_iptables(ips: &mut Ips, cfg: &mut Cfg) {
    //Create the iptables group for JANUS.
    let command: Vec<String> = vec![cfg.iptables_bin.to_string(), " -N JANUS".to_string()];
    println!("Executing {}", command.join(""));
    let output: std::process::Output = Command::new(command.join("")).output().expect("Failed to create the iptables group");
    println!("{}", String::from_utf8_lossy(&output.stdout));

    //Flush the iptables group for JANUS.
    let command: Vec<String> = vec![cfg.iptables_bin.to_string(), " -F JANUS".to_string()];
    println!("Executing {}", command.join(""));
    let output: std::process::Output = Command::new(command.join("")).output().expect("Failed to flush the iptables group");
    println!("{}", String::from_utf8_lossy(&output.stdout));

    //Add the ips to the iptables group.
    for ip in ips.blacklist.iter() {
        let command: Vec<String> = vec![cfg.iptables_bin.to_string(), " -A JANUS -s".to_string(), ip.to_string(), " -j DROP".to_string()];
        println!("Executing {}", command.join(""));
        let output: std::process::Output = Command::new(command.join("")).output().expect("Failed to add the IP to the group");
        println!("{}", String::from_utf8_lossy(&output.stdout));
    }

    // Create the folder for saving the iptables config too.
    if !Path::new(&cfg.iptables_cfg_folder).is_dir() {
        let command: Vec<String> = vec!["mkdir ".to_string(), cfg.iptables_cfg_folder.to_string()];
        println!("Executing {}", command.join(""));
        let output: std::process::Output = Command::new(command.join("")).output().expect("Failed to create the iptables config folder");
        println!("{}", String::from_utf8_lossy(&output.stdout));
    }

    // Save the iptables config v4 file.
    let command: Vec<String> = vec![cfg.iptables_bin.to_string(), "-save > ".to_string(), cfg.iptables_cfg_folder.to_string(), cfg.iptables_cfg_file_v4.to_string()];
    println!("Executing {}", command.join(""));
    let output: std::process::Output = Command::new(command.join("")).output().expect("Failed to save the iptables v4 config");
    println!("{}", String::from_utf8_lossy(&output.stdout));
}

/**
 * Write the IPs to the ips.json.
 */
fn write_ips(path: String, ips: &mut Ips) {
    println!("Writing IPs JSON");

    let json: String = serde_json::to_string(&ips).expect("Failed to convert IPs to JSON");
    fs::write(path, json).expect("Failed to write the IPs JSON");
}