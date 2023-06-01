/**
 * Janus whitelist builder
 *
 * @package     Janus\Controllers\Whitelist
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

class Whitelist extends Controller
{
    public routes = [
        "/whitelist/add": "add",
        "/whitelist/delete/": "delete",
        "/whitelist/edit/": "edit",
        "/whitelist/black/": "blacklist",
        "/whitelist": "index"
    ];

    public function add(string path)
    {
        var html, status;
        let html = this->pageTitle("Create an entry");

        if (isset(_POST["save"])) {
            if (!this->validate(_POST, ["ip"])) {
                let html .= this->error();
            } else {
                var country, service, whois, data;
                let country = "UNKNOWN";
                if (this->settings->ip_lookup) {
                    let country = this->getCountry(_POST["ip"]);
                }

                let service = "UNKNOWN";
                let whois = "UNKNOWN";
                if (this->settings->service_lookup) {
                    let data = this->getService(_POST["ip"]);
                    let whois = data[0];
                    if (data[1]) {
                        let service = data[1];
                    }
                }

                let status = this->db->execute(
                    "INSERT OR REPLACE INTO whitelist
                        (id, 'ip', 'country', 'service', 'whois') 
                    VALUES 
                        (
                            (SELECT id FROM whitelist WHERE ip=:ip),
                            :ip,
                            :country,
                            :service,
                            :whois
                        )",
                    [
                        "ip": _POST["ip"],
                        "country": country,
                        "service": service,
                        "whois": whois
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                unset(_POST["ip"]);
                let html .= this->info("Entry created");
                this->writeCronFiles();
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>IP<span class='required'>*</span></th>
                        <td>
                            <input name='ip' type='text' value='" . (isset(_POST["ip"]) ? _POST["ip"] : "") . "'>
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
            <a href='" . this->urlAddKey("/whitelist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }

    public function blacklist(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/blacklist/black/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM whitelist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        
        let status = this->db->execute(
            "INSERT OR REPLACE INTO blacklist
                (id, 'ip', 'country', 'whois', 'service') 
            VALUES 
                (
                    (SELECT id FROM blacklist WHERE ip=:ip),
                    :ip,
                    :country,
                    :whois,
                    :service
                )",
            [
                "ip": data->ip,
                "country": data->country,
                "service": data->service,
                "whois": data->whois
            ]
        );
        if (!is_bool(status)) {
            throw new Exception(status);
        } 

        this->writeCronFiles();
        this->redirect(this->urlAddKey("/whitelist?blacklist=true"));
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/blacklist/delete/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM whitelist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        }

        this->writeCronFiles();
        this->redirect(this->urlAddKey("/whitelist?deleted=true"));
    }

    public function edit(string path)
    {
        var html, data;
        let html = this->pageTitle("Whitelist IP");

        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/whitelist/edit/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let html .= "
        <table class='table wfull'>
            <tbody>
                <tr>
                    <th>IP</th>
                    <td>" . data->ip . "</td>
                </tr>
                <tr>
                    <th>Country</th>
                    <td>" . data->country . "</td>
                </tr>
                <tr>
                    <th>Service</th>
                    <td>" . data->service . "</td>
                </tr>
                <tr>
                    <th colspan='2'>Whois</th>
                </tr>
                <tr>
                    <td colspan='2' class='log-output'>" . data->whois . "</td>
                </tr>
            </tbody>
        </table>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/whitelist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/whitelist/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
            <a href='" . this->urlAddKey("/whitelist/black/" . data->id) . "' class='round icon icon-blacklist align-right' title='Blacklist the entry'>&nbsp;</a>
        </div>";

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Whitelist IPs");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted and will be removed from whitelist");
        } elseif (isset(_GET["blacklist"])) {
            let html .= this->info("Entry has been marked for blacklisting");
        }
        
        let data = this->db->all("SELECT * FROM whitelist");
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th width='200px'>IP</th>
                        <th>Country</th>
                        <th>Service</th>
                        <th class='buttons' width='140px'>
                            <a href='" . this->urlAddKey("/whitelist/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->ip . "</td>
                    <td>" . item->country . "</td>
                    <td>" . item->service . "</td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/whitelist/edit/" . item->id) . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/whitelist/black/" . item->id) . "' class='mini icon icon-blacklist' title='Blacklist the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/whitelist/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>Nothing whitelisted yet</span></h2>
                <p><a href='" . this->urlAddKey("/whitelist/add") . "' class='round icon icon-add'>&nbsp;</a></p>";
        }
        return html;
    }
}