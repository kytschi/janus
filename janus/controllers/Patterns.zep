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
        "/patterns/export": "export",
        "/patterns/import": "import",
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
                let data = this->db->get(
                    "SELECT id FROM block_patterns WHERE pattern=:pattern",
                    ["pattern":  _POST["pattern"]]
                );
                if (!empty(data)) {
                    return;
                }
                let status = this->db->execute(
                    "INSERT INTO block_patterns
                        (id, 'pattern', 'label', 'category', 'note') 
                    VALUES 
                        (
                            :pattern,
                            :label,
                            :category,
                            :note
                        )",
                    [
                        "pattern": _POST["pattern"],
                        "label": _POST["label"],
                        "category": isset(_POST["category"]) ? _POST["category"] : "None",
                        "note": isset(_POST["note"]) ? _POST["note"] : ""
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
                    <tr>
                        <th>Note</th>
                        <td>
                            <textarea name='note' rows='6'>" . (isset(_POST["note"]) ? _POST["note"] : "") . "</textarea>
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
            <a href='" . this->urlAddKey("/patterns") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM block_patterns WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/patterns/delete/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM block_patterns WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        this->redirect(this->urlAddKey("/patterns?deleted=true"));
    }

    public function edit(string path)
    {
        var html, data, status;
        let html = this->pageTitle("Editting the pattern");

        let data = this->db->get(
            "SELECT * FROM block_patterns WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/patterns/edit/")
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
                        pattern=:pattern,
                        label=:label,
                        category=:category,
                        note=:note
                    WHERE
                        id=:id",
                    [
                        "id": data->id,
                        "pattern": _POST["pattern"],
                        "label": _POST["label"],
                        "category": isset(_POST["category"]) ? _POST["category"] : "None",
                        "note": isset(_POST["note"]) ? _POST["note"] : ""
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
                            <input name='label' type='text' value='" . 
                                (isset(_POST["label"]) ? _POST["label"] : htmlentities(data->label)) .
                            "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Pattern<span class='required'>*</span></th>
                        <td>
                            <input name='pattern' type='text' value='" . 
                                (isset(_POST["pattern"]) ? _POST["pattern"] : htmlentities(data->pattern)) 
                            . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Category</th>
                        <td>
                            <input name='category' type='text' value='" . 
                                (isset(_POST["category"]) ? _POST["category"] : htmlentities(data->category)) . 
                            "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Note</th>
                        <td>
                            <textarea name='note' rows='6'>" . (isset(_POST["note"]) ? _POST["note"] : data->note) . "</textarea>
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
            <a href='" . this->urlAddKey("/patterns") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/patterns/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
        </div>";

        return html;
    }

    public function export(string path)
    {
        var item, data, iLoop = 0, query, vars = [], head, colon = false;

        let query = "SELECT * FROM block_patterns";
        if (isset(_GET["p"])) {
            let query .= " WHERE pattern=:query";
            let vars["query"] = urldecode(_GET["p"]);
        } elseif (isset(_GET["c"])) {
            let query .= " WHERE category=:query";
            let vars["query"] = urldecode(_GET["c"]);
        }
        let query .= " ORDER BY pattern";

        let data = this->db->all(query, vars);
        if (empty(data)) {
            throw new Exception("No patterns to export");
        }
        
        header("Content-Type: application/sql");
        header("Content-Disposition: attachment; filename=janus_" . date("Y_m_d_H_i_s") . ".jim");
        let head = "REPLACE INTO block_patterns (`id`, `pattern`, `label`, `category`) VALUES";
        echo head;
        for iLoop, item in data {
            echo "\n(
                (SELECT id FROM block_patterns AS src WHERE pattern=\"" . item->pattern . "\" LIMIT 1), 
                \"" . addslashes(item->pattern) . "\", 
                \"" . addslashes(item->label) . "\", 
                \"" . addslashes(item->category) . "\"
            )";
            if (!fmod(iLoop + 1, 20)) {
                let colon = true;
                echo ";/*ENDJIM*/";
                echo head;
            } elseif (iLoop < count(data) - 1) {
                let colon = false;
                echo ",";
            }
        }
        if (!colon) {
            echo ";/*ENDJIM*/";
        }
        die();
    }

    public function index(string path)
    {
        var html, data, query, vars=[], categories, categories_query, 
            item, filter = "", page = 1, count, where = "";
        let html = this->pageTitle("Block patterns");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted");
        }

        if (isset(_GET["page"])) {
            let page = intval(_GET["page"]);
            if (empty(page)) {
                let page = 1;
            }
        }

        let count = "SELECT count(id) AS total FROM block_patterns";
        let query = "SELECT * FROM block_patterns";
        let categories_query = "SELECT category FROM block_patterns";
        if (isset(_POST["q"])) {
            let where .= " WHERE pattern LIKE :query";
            let vars["query"] = "%" . _POST["q"] . "%";
            let filter = "?p=" . urlencode(_POST["q"]);
        } elseif (isset(_GET["c"])) {
            let where .= " WHERE category = :query";
            let vars["query"] = urldecode(_GET["c"]);
            let filter = "?c=" . _GET["c"];
        }
        let categories_query .= where . " GROUP BY category ORDER BY category";

        let count = this->db->get(count . where, vars);
        let count = count->total;

        let query .= where . " ORDER BY pattern LIMIT " . page . ", " . this->per_page;
        
        let categories = this->db->all(categories_query, vars);
        let data = this->db->all(query, vars);
        if (count) {
            let html .= "
                <form action='" . this->urlAddKey("/patterns") . "' method='post'>
                    <table class='table wfull'>
                        <tr>
                            <th>Pattern<span class='required'>*</span></th>
                            <td>
                                <input name='q' type='text' value='" . (isset(_POST["q"]) ? _POST["q"]  : ""). "'>
                            </td>
                        </tr>
                        <tfoot>
                            <tr>
                                <td colspan='2'>
                                    <button type='submit' name='search' value='search' class='float-right'>search</button>";
            if (isset(_POST["q"])) {
                let html .= "<a href='" . this->urlAddKey("/patterns") . "' class='float-right button'>clear</a>";
            }
            let html .= "</td>
                            </tr>
                        </tfoot>
                    </table>
                </form>";

            if (categories) {
                let html .= "<div id='tags' class='wfull'>";
                for item in categories {
                    let html .= "<a class='tag' href='" . this->urlAddKey("/patterns?c=" . urlencode(item->category)) . "'>" . item->category . "</a>";
                }
                if (isset(_GET["c"])) {
                    let html .= "<a href='" . this->urlAddKey("/patterns") . "' class='float-left button'>clear filter</a>";
                }
                let html .= "</div>";
            }

            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>Pattern</th>
                        <th width='200px'>Label</th>
                        <th width='200px'>Category</th>
                        <th class='buttons' width='120px'>
                            <a href='" . this->urlAddKey("/patterns/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";            
            for item in data {
                let html .= "<tr>
                    <td>" . item->pattern . "</td>
                    <td>" . item->label . "</td>
                    <td>" . item->category . "</td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/patterns/edit/" . item->id) . "' class='mini icon icon-edit' title='View/Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/patterns/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";

            let html .= this->pagination(count, page, "/patterns");
        } else {
            let html .= "<h2><span>No patterns found</span></h2>";
            if (isset(_POST["q"])) {
                let html .= "<p><a href='" . this->urlAddKey("/patterns") . "' class='button'>clear search</a></p>";
            }
        }

        let html .= "<div class='page-toolbar'>
            <a href='" . this->urlAddKey("/patterns/add") . "' class='round icon icon-add'>&nbsp;</a>";
        if (count) {
            let html .= "<a href='" . this->urlAddKey("/patterns/export" . filter) . "' class='round icon icon-export' title='Export Janus patterns'>&nbsp;</a>";
        }
        let html .= "<a href='" . this->urlAddKey("/patterns/import") . "' class='round icon icon-import' title='Import Janus patterns'>&nbsp;</a>
        </div>";

        return html;
    }
}