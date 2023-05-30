/**
 * Janus logs
 *
 * @package     Janus\Controllers\Logs
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

class Logs extends Controller
{
    public routes = [
        "/logs/add": "add",
        "/logs/edit/": "edit",
        "/logs": "index"
    ];

    public function add(string path)
    {
        var html, status;
        let html = this->pageTitle("Creating an entry");

        if (isset(_POST["save"])) {
            let status = this->db->execute(
                "INSERT INTO logs (log) VALUES (:log)",
                [
                    "log": _POST["log"]
                ]
            );

            if (!is_bool(status)) {
                throw new Exception(status);
            }
            let html .= this->info("Entry created");
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Log</th>
                        <td>
                            <input class='form-input' name='log' value=''>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button name='save' value='save' class='float-right' type='submit'>Save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='/logs' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";        

        return html;
    }

    public function edit(string path)
    {
        var html, data, status;
        let html = this->pageTitle("Editing the log");

        let data = this->db->get(
            "SELECT * FROM logs WHERE id=:id",
            [
                "id": str_replace("/logs/edit/", "", path)
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        if (isset(_POST["save"])) {
            let status = this->db->execute(
                "UPDATE logs SET log=:log WHERE id=:id",
                [
                    "id": data->id,
                    "log": _POST["log"]
                ]
            );

            if (!is_bool(status)) {
                throw new Exception(status);
            } 

            let data->log = _POST["log"];
            let html .= this->info("Entry updated");
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Log</th>
                        <td>
                            <input class='form-input' name='log' value='" . data->log . "'>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button name='save' value='save' class='float-right' type='submit'>Save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='/logs' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='/logs/delete/" . data->id . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
        </div>";

        var dir, logs, log, line, lines, iLoop=0;
        let dir = shell_exec("ls " . data->log);
        if (!empty(dir)) {
            let html .= "<h2><span>The log</span></h2>
            <table class='table wfull'>
                <thead>
                    <tr>
                        <th>Line</th>
                        <th width='60px'>&nbsp;</th>
                    </tr>
                </thead>
                <tbody>";

            let logs = explode("\n", dir);
            for log in logs {
                if (empty(log)) {
                    continue;
                }

                let lines = explode("\n", file_get_contents(log));
                if (empty(lines)) {
                    continue;
                }

                for iLoop, line in lines {
                    if (empty(line)) {
                        continue;
                    }
                    let html .= "<tr>
                        <td><pre>" . line . "</pre></td>
                        <td>&nbsp;</td>
                    </tr>";
                }
            }

            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>Failed to read the log</span></h2>";
        }
        

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Logs to watch");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted");
        }
        
        let data = this->db->all("SELECT * FROM logs");
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>Log</th>
                        <th class='buttons' width='120px'>
                            <a href='/logs/add' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->log . "</td>
                    <td class='buttons'>
                        <a href='/logs/edit/" . item->id . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='/logs/delete/" . item->id . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>No logs defined to watch yet</span></h2>";
        }
        return html;
    }
}