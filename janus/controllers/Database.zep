/**
 * Janus database hanlder
 *
 * @package     Janus\Controllers\Database
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

use Janus\Exceptions\Exception;

class Database
{
    private db;

    public function __construct(string db_file)
    {
        let this->db = new \PDO("sqlite:" . db_file);
    }

    public function all(string query, array data = [])
    {
        var statement;
        let statement = this->db->prepare(query);
        statement->execute(data);
        return statement->fetchAll(\PDO::FETCH_CLASS, "Janus\\Models\\Model");
    }

    public function execute(string query, array data = [], bool always_save = false)
    {
        var statement, status, errors;

        ob_start();
        let statement = this->db->prepare(query);
        let status = statement->execute(data);
        let errors = ob_get_contents();
        ob_end_clean();

        if (!status) {
            return errors;
        }

        return status;
    }

    public function get(string query, array data = [])
    {
        var statement;
        let statement = this->db->prepare(query);
        statement->execute(data);
        return statement->fetchObject("Janus\\Models\\Model");
    }
}