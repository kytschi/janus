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
                        "firewall_command",
                        "cron_folder",
                        "firewall_cfg_folder",
                        "firewall_cfg_file_v4"
                    ]
                )
            ) {
                let html .= this->error();
            } else {
                let status = this->db->execute(
                    "UPDATE 
                        settings
                    SET 
                        ip_lookup=:ip_lookup,
                        service_lookup=:service_lookup,
                        firewall_command=:firewall_command,
                        firewall_cfg_folder=:firewall_cfg_folder,
                        firewall_cfg_file_v4=:firewall_cfg_file_v4,
                        cron_folder=:cron_folder",
                    [
                        "ip_lookup": isset(_POST["ip_lookup"]) ? 1 : 0,
                        "service_lookup": isset(_POST["service_lookup"]) ? 1 : 0,
                        "firewall_command": _POST["firewall_command"],
                        "firewall_cfg_folder": rtrim(_POST["firewall_cfg_folder"], "/") . "/",
                        "firewall_cfg_file_v4": _POST["firewall_cfg_file_v4"],
                        "cron_folder": _POST["cron_folder"]
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                let html .= this->info("Settings updated");
            }
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
                        <th>CRON output folder<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='cron_folder'
                                type='text'
                                value='" . (isset(_POST["cron_folder"]) ? _POST["cron_folder"] : data->cron_folder) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Firewall command<span class='required'>*</span></th>
                        <td>
                            <input 
                                name='firewall_command'
                                type='text'
                                value='" . (isset(_POST["firewall_command"]) ? _POST["firewall_command"] : data->firewall_command) . "'>
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
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button type='submit' name='save' value='save' class='float-right'>save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='/users' class='round icon icon-users' title='Users'>&nbsp;</a>
        </div>";

        return html;
    }
}