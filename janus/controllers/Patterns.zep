/**
 * Janus patterns builder
 *
 * @package     Janus\Controllers\Patterns
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

class Patterns extends Controller
{
    public routes = [
        "/patterns/add": "add",
        "/patterns/delete/": "delete",
        "/patterns/edit/": "edit",
        "/patterns": "index"
    ];

    public function add(string path)
    {
        var data, pattern = "", status, html = "";

        let html = this->pageTitle("Adding a pattern");
        if (isset(_POST["save"])) {
            if (!this->validate(_POST, ["pattern", "label"])) {
                let html .= this->error();
            } else {
                let status = this->db->execute(
                    "INSERT OR REPLACE INTO block_patterns
                        (id, 'pattern', 'label', 'category') 
                    VALUES 
                        (
                            (SELECT id FROM block_patterns WHERE pattern=:pattern),
                            :pattern,
                            :label,
                            :category
                        )",
                    [
                        "pattern": _POST["pattern"],
                        "label": _POST["label"],
                        "category": isset(_POST["category"]) ? _POST["category"] : "None"
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                let html .= this->info("Entry created");
            }
        }
        
        if (isset(_POST["pattern"])) {
            let pattern = _POST["pattern"];
        } elseif (isset(_GET["log"]) && isset(_GET["line"])) {
            let data = this->db->get(
                "SELECT * FROM logs WHERE id=:id",
                [
                    "id": _GET["log"]
                ]
            );

            if (empty(data)) {
                throw new Exception("Log not found");
            }

            var dir, logs, log, lines;
            let dir = shell_exec("ls " . data->log);
            if (!empty(dir)) {
                let logs = explode("\n", dir);
                for log in logs {
                    if (empty(log)) {
                        continue;
                    }

                    let lines = explode("\n", file_get_contents(log));
                    if (empty(lines)) {
                        throw new Exception("Failed to read the log");
                    }

                    if (!isset(lines[_GET["line"]])) {
                        throw new Exception("Log line not found");
                    }

                    let pattern = lines[_GET["line"]];
                    break;
                }
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Label<span class='required'>*</span></th>
                        <td>
                            <input name='label' type='text' value='" . (isset(_POST["label"]) ? _POST["label"] : "") . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Pattern<span class='required'>*</span></th>
                        <td>
                            <input name='pattern' type='text' value='" . pattern . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Category</th>
                        <td>
                            <input name='category' type='text' value='" . (isset(_POST["category"]) ? _POST["category"] : "") . "'>
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
            <a href='/patterns' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM block_patterns WHERE id=:id",
            [
                "id": str_replace("/patterns/delete/", "", path)
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM block_patterns WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        this->redirect("/patterns?deleted=true");
    }

    public function edit(string path)
    {
        var html, data, status;
        let html = this->pageTitle("Editting the pattern");

        let data = this->db->get(
            "SELECT * FROM block_patterns WHERE id=:id",
            [
                "id": str_replace("/patterns/edit/", "", path)
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        if (isset(_POST["save"])) {
            if (!this->validate(_POST, ["pattern", "label"])) {
                let html .= this->error();
            } else {
                let status = this->db->execute(
                    "UPDATE 
                        block_patterns
                    SET 
                        pattern=:pattern, label=:label, category=:category
                    WHERE
                        id=:id",
                    [
                        "id": data->id,
                        "pattern": _POST["pattern"],
                        "label": _POST["label"],
                        "category": isset(_POST["category"]) ? _POST["category"] : "None"
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                let html .= this->info("Entry updated");
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Label<span class='required'>*</span></th>
                        <td>
                            <input name='label' type='text' value='" . (isset(_POST["label"]) ? _POST["label"] : data->label) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Pattern<span class='required'>*</span></th>
                        <td>
                            <input name='pattern' type='text' value='" . (isset(_POST["pattern"]) ? _POST["pattern"] : data->pattern) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Category</th>
                        <td>
                            <input name='category' type='text' value='" . (isset(_POST["category"]) ? _POST["category"] : data->category) . "'>
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
            <a href='/patterns' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='/patterns/delete/" . data->id . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
        </div>";

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Block patterns");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted");
        }
        
        let data = this->db->all("SELECT * FROM block_patterns ORDER BY pattern");
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>Pattern</th>
                        <th width='200px'>Label</th>
                        <th width='200px'>Category</th>
                        <th class='buttons' width='120px'>
                            <a href='/patterns/add' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->pattern . "</td>
                    <td>" . item->label . "</td>
                    <td>" . item->category . "</td>
                    <td class='buttons'>
                        <a href='/patterns/edit/" . item->id . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='/patterns/delete/" . item->id . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "
                <h2><span>No patterns yet</span></h2>
                <p><a href='/patterns/add' class='round icon icon-add'>&nbsp;</a></p>";
        }
        return html;
    }
}