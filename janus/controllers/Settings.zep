/**
 * Janus settings
 *
 * @package     Janus\Controllers\Settings
 * @author 		Mike Welsh
 * @copyright   2025 Mike Welsh
 * @version     0.0.2
 *
 * Copyright 2025 Mike Welsh
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301, USA.
*/
namespace Janus\Controllers;

use Janus\Controllers\Controller;
use Janus\Exceptions\Exception;

class Settings extends Controller
{
    public routes = [
        "/settings/iptablesv4": "iptablesVFour",
        "/settings/iptablesv6": "iptablesVSix",
        "/settings": "index"
    ];

    public function index(string path)
    {
        var html, data, status, ip, ips = [], found, lines, iLoop;
        let html = this->pageTitle("Settings");

        if (isset(_POST["save"])) {
            if (!this->validate(
                    _POST,
                    [
                        "webuser",
                        "firewall_command",
                        "firewall_command_v6",
                        "cron_folder",
                        "firewall_cfg_folder",
                        "firewall_cfg_file_v4",
                        "firewall_cfg_file_v6"
                    ]
                )
            ) {
                let html .= this->error();
            } else {
                let status = this->db->execute(
                    "UPDATE 
                        settings
                    SET 
                        webuser=:webuser,
                        ip_lookup=:ip_lookup,
                        service_lookup=:service_lookup,
                        firewall_command=:firewall_command,
                        firewall_command_v6=:firewall_command_v6,
                        firewall_cfg_folder=:firewall_cfg_folder,
                        firewall_cfg_file_v4=:firewall_cfg_file_v4,
                        firewall_cfg_file_v6=:firewall_cfg_file_v6,
                        cron_folder=:cron_folder",
                    [
                        "webuser": _POST["webuser"],
                        "ip_lookup": isset(_POST["ip_lookup"]) ? 1 : 0,
                        "service_lookup": isset(_POST["service_lookup"]) ? 1 : 0,
                        "firewall_command": _POST["firewall_command"],
                        "firewall_command_v6": _POST["firewall_command_v6"],
                        "firewall_cfg_folder": rtrim(_POST["firewall_cfg_folder"], "/") . "/",
                        "firewall_cfg_file_v4": _POST["firewall_cfg_file_v4"],
                        "firewall_cfg_file_v6": _POST["firewall_cfg_file_v6"],
                        "cron_folder": _POST["cron_folder"]
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                let html .= this->info("Settings updated");
                let this->settings = this->db->get("
                    SELECT
                        *,
                        '" . this->settings->db_file . "' AS db_file, 
                        '" . this->settings->url_key_file . "' AS url_key_file, 
                        '" . this->settings->url_key . "' AS url_key  
                    FROM settings LIMIT 1");
                this->writeCronFiles();
            }
        } elseif (isset(_POST["reset_cron"])) {
            let status = this->db->execute("UPDATE settings SET cron_running=0");

            if (!is_bool(status)) {
                throw new Exception(status);
            }
            let html .= this->info("Cleared the running cron flag");
        } elseif (isset(_POST["rebuild_cron"])) {
            this->writeCronFiles(true);
            let html .= this->info("Cron has been rebuilt");
        }
        
        let lines = explode("\n", shell_exec("ip a | grep -e \"inet\" -e \"link\""));
        let iLoop = 0;
        for status in lines {
            if (empty(status)) {
                continue;
            }
            
            if (strpos(status, "link/") !== false) {
                let ip = [];
                let data = explode(" ", trim(status));
                let ip[0] = data[1];
            } elseif (strpos(status, "inet") !== false) {
                let data = explode(" ", trim(status));
                let ip[1] = str_replace(["/8", "/24", "/64"], "", data[1]);
                let ip[2] = data[0];
                let ips[iLoop] = ip;
                let iLoop = iLoop + 1;
            } else {
                continue;
            }
        }
        
        let html .= "
        <div class='row'>
            <div class='tag'>System IP(s)</div>
        </div>
        <div class='row'>
            <table class='table wfull'>
                <thead>
                    <tr>
                        <th>IP</th>
                        <th>MAC</th>
                        <th>Type</th>
                        <th>&nbsp;</th>
                    </tr>
                </thead>
                <tbody>";
        
        for ip in ips {
            let found = this->db->get(
                "SELECT * FROM whitelist WHERE ip=:ip",
                [
                    "ip": ip[1]
                ]
            );

            let html .= "
                <tr>
                    <td>" . ip[1] . "</td>
                    <td>" . ip[0] . "</td>
                    <td>" . ip[2] . "</td>
                    <td>";

            if (found) {
                let html .= "<a 
                        class='mini icon icon-whitelist active' 
                        title='Found whitelisted IP: " . (found->label ? found->label : found->ip) . "' 
                        href='" . this->urlAddKey("/whitelist/edit/" . found->id) . "'>
                        &nbsp;
                    </a>";
            } else {
                let html .= "<a 
                    title='Create a whitelist entry for IP: " . ip[1] . "' 
                    href='" .this->urlAddKey("/whitelist/add?ip=" . urlencode(ip[1])) . "'
                    class='mini icon icon-whitelist'>&nbsp;</a>";
            }

            let html .= "
                    </td>
                </tr>";
        }
        let html .= "</tbody>
            </table>
        </div>";

        let data = this->db->get("SELECT * FROM settings LIMIT 1");
        if (empty(data)) {
            throw new Exception("Failed to read the settings");
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>IP lookup</th>
                        <td>
                            <div class='switcher'>
                                <label>
                                    <input type='checkbox' name='ip_lookup' value='1' " . (data->ip_lookup ? " checked='checked'" : "") . ">
                                    <span>
                                        <small class='switcher-on'></small>
                                        <small class='switcher-off'></small>
                                    </span>
                                </label>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <th>Service lookup</th>
                        <td>
                            <div class='switcher'>
                                <label>
                                    <input type='checkbox' name='service_lookup' value='1' " . (data->service_lookup ? " checked='checked'" : "") . ">
                                    <span>
                                        <small class='switcher-on'></small>
                                        <small class='switcher-off'></small>
                                    </span>
                                </label>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <th>Web user<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='webuser'
                                type='text'
                                value='" . (isset(_POST["webuser"]) ? _POST["webuser"] : data->webuser) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>CRON output folder<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='cron_folder'
                                type='text'
                                value='" . (isset(_POST["cron_folder"]) ? _POST["cron_folder"] : data->cron_folder) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Firewall command for IPv4<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='firewall_command'
                                type='text'
                                value='" . (isset(_POST["firewall_command"]) ? _POST["firewall_command"] : data->firewall_command) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Firewall command for IPv6<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='firewall_command_v6'
                                type='text'
                                value='" . (isset(_POST["firewall_command_v6"]) ? _POST["firewall_command_v6"] : data->firewall_command_v6) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Firewall cfg folder<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='firewall_cfg_folder'
                                type='text'
                                value='" . (isset(_POST["firewall_cfg_folder"]) ? _POST["firewall_cfg_folder"] : data->firewall_cfg_folder) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Firewall cfg file for IPv4<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='firewall_cfg_file_v4'
                                type='text'
                                value='" . (isset(_POST["firewall_cfg_file_v4"]) ? _POST["firewall_cfg_file_v4"] : data->firewall_cfg_file_v4) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Firewall cfg file for IPv6<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='firewall_cfg_file_v6'
                                type='text'
                                value='" . (isset(_POST["firewall_cfg_file_v6"]) ? _POST["firewall_cfg_file_v6"] : data->firewall_cfg_file_v6) . "'>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td>
                            <a 
                                href='" . this->urlAddKey("/settings/iptablesv4") . "'
                                class='button'
                                title='Show iptables list'>IPTables v4</a>
                            <a 
                                href='" . this->urlAddKey("/settings/iptablesv6") . "'
                                class='button'
                                title='Show iptables list'>IPTables v6</a>
                        </td>
                        <td>
                            <button type='submit' name='save' value='save' class='float-right'>save</button>
                            <button 
                                type='submit' 
                                name='reset_cron' 
                                value='reset_cron' 
                                class='float-right'>
                                reset cron
                            </button>
                            <button 
                                type='submit' 
                                name='rebuild_cron' 
                                value='rebuild_cron' 
                                class='float-right'>
                                rebuild cron
                            </button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/users") . "' class='round icon icon-users' title='Users'>&nbsp;</a>
        </div>";

        return html;
    }

    public function iptablesVFour(string path)
    {
        var html, file, line;
        let html = this->pageTitle("Settings - IPTables V4");

        let html .= "<div class='page-toolbar'>
            <a href='" . this->urlAddKey("/settings") . "' class='round icon icon-back' title='Back to settings'>&nbsp;</a>
        </div>
        <div class='row'><table class='table wfull'><tbody><tr><td><pre><code>";

        let file = fopen(rtrim(this->settings->cron_folder, "/") . "/iv4", "r");
        let line = fgets(file);
        while (line !== false) {
            let html .= line;
            let line = fgets(file);
        }
        fclose(file);

        let html .= "</code></pre></td></tr></tbody></table></div>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/settings") . "' class='round icon icon-back' title='Back to settings'>&nbsp;</a>
        </div>";

        return html;
    }

    public function iptablesVSix(string path)
    {
        var html, file, line;
        let html = this->pageTitle("Settings - IPTables V6");

        let html .= "<div class='page-toolbar'>
            <a href='" . this->urlAddKey("/settings") . "' class='round icon icon-back' title='Back to settings'>&nbsp;</a>
        </div>
        <div class='row'><table class='table wfull'><tbody><tr><td><pre><code>";

        let file = fopen(rtrim(this->settings->cron_folder, "/") . "/iv6", "r");
        let line = fgets(file);
        while (line !== false) {
            let html .= line;
            let line = fgets(file);
        }
        fclose(file);

        let html .= "</code></pre></td></tr></tbody></table></div>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/settings") . "' class='round icon icon-back' title='Back to settings'>&nbsp;</a>
        </div>";

        return html;
    }
}