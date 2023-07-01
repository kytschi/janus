/**
 * Janus settings
 *
 * @package     Janus\Controllers\Settings
 * @author 		Mike Welsh
 * @copyright   2023 Mike Welsh
 * @version     0.0.1
 *
 * Copyright 2023 Mike Welsh
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
        "/settings": "index"
    ];

    public function index(string path)
    {
        var html, data, status;
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
        }
        
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
                        <td colspan='2'>
                            <button type='submit' name='save' value='save' class='float-right'>save</button>
                            <button 
                                type='submit' 
                                name='reset_cron' 
                                value='reset_cron' 
                                class='float-right'>
                                reset cron
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
}