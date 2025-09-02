/**
 * Janus controller
 *
 * @package     Janus\Controllers\Controller
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
use Janus\Ui\Head;

class Controller
{
    public db;
    public routes = [];
    public settings;

    public per_page = 100;

    public function cleanUrl(string path, string clean)
    {
        return str_replace(
            "/" . (this->settings ? this->settings->url_key : "") . clean,
            "",
            path
        );
    }

    public function error(string message = "Missing required fields")
    {
        return "<div class='error box wfull'>
        <div class='box-title'>
            <span>Error</span>
        </div>
        <div class='box-body'>
            <p>" . message . "</p>
        </div></div>";
    }

    public function getCountry(ip)
    {
        var output, splits;
        let output = shell_exec("geoiplookup " . ip);
        if (output) {
            let splits = explode(":", output);
            let splits = explode(",", splits[count(splits) - 1]);
            unset(splits[0]);
            let output = trim(implode(",", splits));
            return (output) ? output : "UNKNOWN";
        }
        return "UNKNOWN";
    }

    public function getIP(string line, bool single = true)
    {
        var ip, matches, ips = [];

        preg_match_all(
            "/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/",
            line,
            matches
        );
        
        if (empty(matches[0])) {
            return null;
        }

        for ip in matches[0] {
            if (
                strpos(line, "/" . ip) === false &&
                !strtotime(ip)
            ) {
                if (single) {
                    return ip;
                } else {
                    let ips[] = ip;
                }
            }
        }

        return ips;
    }

    public function getIPVSIX(string line, bool single = true)
    {
        var ip, matches, ips = [];

        preg_match_all(
            "/([a-f0-9:]+:+)+[a-f0-9]+/",
            line,
            matches
        );
        
        if (empty(matches[0])) {
            return null;
        }

        for ip in matches[0] {
            if (
                strpos(line, "/" . ip) === false &&
                !strtotime(ip) &&
                substr_count(ip, ":") > 1
            ) {
                if (single) {
                    return ip;
                } else {
                    let ips[] = ip;
                }
            }
        }

        return ips;
    }

    public function getService(ip)
    {
        var output, line, lines, netname = null;

        let output = shell_exec("whois " . ip);
        if (output) {
            let lines = explode("\n", strtolower(output));
            
            for line in lines {
                if(strpos(line, "orgname:") !== false) {
                    let netname = trim(ltrim(line, "orgname:"));
                    break;
                }

                if(strpos(line, "org-name:") !== false && !netname) {
                    let netname = trim(ltrim(line, "org-name:"));
                }

                if(strpos(line, "netname:") !== false) {
                    let netname = trim(ltrim(line, "netname:"));
                }

                if(strpos(line, "owner:") !== false && !netname) {
                    let netname = trim(ltrim(line, "owner:"));
                }

                if(strpos(line, "organization name") !== false && !netname) {
                    let netname = str_replace([":"], "", trim(ltrim(line, "organization name")));
                }
                

                if(strpos(line, "descr:") !== false && netname) {
                    let netname = trim(ltrim(line, "descr:"));
                    break;
                }
            }
        }
        
        return [
            output,
            (netname) ? ucwords(strtolower(netname)) : "UNKNOWN"
        ];
    }

    public function import(string path)
    {
        var data, status, html = "", sql;

        let html = this->pageTitle("Importing");
        if (isset(_POST["save"])) {
            if (!this->validate(_FILES, ["file"])) {
                let html .= this->error();
            } else {
                let data = explode(";/*ENDJIM*/", file_get_contents(_FILES["file"]["tmp_name"]));                
                for sql in data {
                    if (empty(sql)) {
                        continue;
                    }
                    try {
                        let status = this->db->execute(sql);
                    } catch \Exception, status {
                        throw new Exception(status->getMessage());
                    }
                    if (!is_bool(status)) {
                        throw new Exception(status);
                    }
                }
                let html .= this->info("Import successful");
            }
        }
        
        
        let html .= "
        <form method='POST' enctype='multipart/form-data'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>File<span class='required'>*</span></th>
                        <td>
                            <input name='file' type='file' accept='.jim'>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button type='submit' name='save' value='save' class='float-right'>import</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='" . str_replace("/import", "", path) . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }

    public function info(string message)
    {
        return "<div class='info box wfull'>
            <div class='box-title'>
                <span>Info</span>
            </div>
            <div class='box-body'>
                <p>" . message . "</p>
            </div></div>";
    }

    public function pageTitle(string title, bool toolbar = true)
    {
        var head;
        let head = new Head(this->settings);

        return "<h1><span>" . title . "</span></h1>" . (toolbar ? head->toolbar() : "");
    }

    public function pagination(int count, int page, string url)
    {
        var html, pages = 1, start = 1, end = 10;

        let pages = intval(count / this->per_page);
        if (pages < 1) {
            let pages = 1;
        }
        if ((pages * this->per_page) < count) {
            let pages += 1;
        }
        if (page >= end) {
            let start = intval(page / 10) * 10;
        }

        let end = start + 9;
        if (end > pages) {
            let end = pages;
        }

        let html = "
        <div class='pagination w-100'>
            <span>" . count  . " result(s)</span><div>";

        let html .= "<a href='" . this->urlAddKey(url) . "?page=1'>&lt;&lt;</a>";
        let html .= "<a href='" . this->urlAddKey(url) . "?page=" . (page == 1 ? 1 : page - 1). "'>&lt;</a>";

        while(start <= end) {
            let html .= "<a href='" . this->urlAddKey(url) . "?page=" . start . "'";
            if (start == page) {
                let html .= " class='selected'";
            }
            let html .= ">" . start . "</a>";
            let start += 1;
        }

        let html .= "<a href='" . this->urlAddKey(url) . "?page=" . (page == pages ? pages : page + 1). "'>&gt;</a>";
        let html .= "<a href='" . this->urlAddKey(url) . "?page=" . pages . "'>&gt;&gt;</a>";

        let html .= "</div></div>";

        return html;
    }

    public function redirect(string url)
    {
        header("Location: " . url);
        die();
    }

    public function router(string path, database, settings)
    {
        var route, func;

        let this->db = database;
        let this->settings = settings;

        for route, func in this->routes {
            if (strpos(path, this->urlAddKey(route)) !== false) {
                return this->{func}(path);
            }
        }

        return "";
    }

    public function urlAddKey(string path)
    {
        return "/" . (this->settings ? this->settings->url_key : "") . path;
    }

    public function validate(array data, array checks)
    {
        var iLoop = 0;
        while (iLoop < count(checks)) {
            if (!isset(data[checks[iLoop]])) {
                return false;
            }
            
            if (empty(data[checks[iLoop]])) {
                return false;
            }
            let iLoop = iLoop + 1;
        }
        return true;
    }

    public function writeCronFiles(bool write_files = false)
    {
        var err, data, item, file;

        try {
            if (write_files) {
                // Write the blacklist IPs for CRON.
                let data = this->db->all("SELECT * FROM blacklist WHERE ipvsix=0");
                let file = fopen(rtrim(this->settings->cron_folder, "/") . "/blacklist", "w");
                if (!file) {
                    throw new Exception("Failed to write blacklist file for CRON");
                }
                for item in data {
                    fwrite(file, item->ip. "\n");
                }
                fclose(file);
                let data = this->db->all("SELECT * FROM blacklist WHERE ipvsix=1");
                let file = fopen(rtrim(this->settings->cron_folder, "/") . "/blacklistv6", "w");
                if (!file) {
                    throw new Exception("Failed to write blacklist V6 file for CRON");
                }
                for item in data {
                    fwrite(file, item->ip. "\n");
                }
                fclose(file);

                // Write the whitelist IPs for CRON.
                let data = this->db->all("SELECT * FROM whitelist WHERE ipvsix=0");
                let file = fopen(rtrim(this->settings->cron_folder, "/") . "/whitelist", "w");
                if (!file) {
                    throw new Exception("Failed to write whitelist file for CRON");
                }
                for item in data {
                    fwrite(file, item->ip . "\n");
                }
                fclose(file);
                let data = this->db->all("SELECT * FROM whitelist WHERE ipvsix=1");
                let file = fopen(rtrim(this->settings->cron_folder, "/") . "/whitelistv6", "w");
                if (!file) {
                    throw new Exception("Failed to write whitelist V6 file for CRON");
                }
                for item in data {
                    fwrite(file, item->ip . "\n");
                }
                fclose(file);
            }
                    
            // Write the cron.
            shell_exec("rm " . rtrim(this->settings->cron_folder, "/") . "/cron.sh");
            file_put_contents(
                rtrim(this->settings->cron_folder, "/") . "/cron.sh",
                "# !/bin/bash
# DO NOT EDIT, AUTOMATICALLY CREATED BY JANUS
# Created on " . date("Y-d-m H:i:s") . "

php -r \"use Janus\\Janus; new Janus('" . this->settings->db_file . "', '" . this->settings->url_key_file . "', true);\";

DIR=$(dirname -- \"$0\";)
WEBUSER=\"" . this->settings->webuser . "\"
IPTABLES=" . this->settings->firewall_command . "
IPTABLESVSIX=" . this->settings->firewall_command_v6 . "

chainAdd () {
    chain=`$IPTABLES -n --list INPUT | grep $1`
    if [ -z \"$chain\" ]; then
            # Add the chain to INPUT
            $IPTABLES -A INPUT -j $1
    fi
}

chainAddVSIX () {
    chain=`$IPTABLESVSIX -n --list INPUT | grep $1`
    if [ -z \"$chain\" ]; then
            # Add the chain to INPUT
            $IPTABLESVSIX -A INPUT -j $1
    fi
}

IP_BLACKLIST=$DIR/blacklist
IP_BLACKLISTVSIX=$DIR/blacklistv6
IP_WHITELIST=$DIR/whitelist
IP_WHITELISTVSIX=$DIR/whitelistv6
CONF=" . this->settings->firewall_cfg_folder . this->settings->firewall_cfg_file_v4 . "
CONFVSIX=" . this->settings->firewall_cfg_folder . this->settings->firewall_cfg_file_v6 . "

# Set the files to writeable by webuser.
chown $WEBUSER:$WEBUSER $IP_BLACKLIST
chown $WEBUSER:$WEBUSER $IP_BLACKLISTVSIX
chown $WEBUSER:$WEBUSER $IP_WHITELIST
chown $WEBUSER:$WEBUSER $IP_WHITELISTVSIX

# Create the chain JANUS_BLACKLIST
$IPTABLES -N JANUS_BLACKLIST > /dev/null
$IPTABLESVSIX -N JANUS_BLACKLIST_V6 > /dev/null

# Add the chain to INPUT
chainAdd JANUS_BLACKLIST
chainAddVSIX JANUS_BLACKLIST_V6
            
# Empty the chain JANUS_BLACKLIST before adding rules
$IPTABLES -F JANUS_BLACKLIST
$IPTABLESVSIX -F JANUS_BLACKLIST_V6
            
# Read $IP_BLACKLIST and add IP into IPTables one by one
/bin/egrep -v \"^#|^$|:\" $IP_BLACKLIST | sort | uniq | while read IP
do
    $IPTABLES -A JANUS_BLACKLIST -s $IP -j DROP
done
# Read $IP_BLACKLISTVSIX and add IP into IPTables one by one
/bin/egrep -v \"^#|^$\" $IP_BLACKLISTVSIX | sort | uniq | while read IP
do
    $IPTABLESVSIX -A JANUS_BLACKLIST_V6 -s $IP -j DROP
done

# Create the chain JANUS_WHITELIST
$IPTABLES -N JANUS_WHITELIST > /dev/null
$IPTABLESVSIX -N JANUS_WHITELIST_V6 > /dev/null

# Add the chain to INPUT
chainAdd JANUS_WHITELIST
chainAddVSIX JANUS_WHITELIST_V6
            
# Empty the chain JANUS_WHITELIST before adding rules
$IPTABLES -F JANUS_WHITELIST
$IPTABLESVSIX -F JANUS_WHITELIST_V6
            
# Read $IP_WHITELIST and add IP into IPTables one by one
/bin/egrep -v \"^#|^$|:\" $IP_WHITELIST | sort | uniq | while read IP
do
    $IPTABLES -A JANUS_WHITELIST -s $IP -j ACCEPT
done
# Read $IP_WHITELISTVSIX and add IP into IPTables one by one
/bin/egrep -v \"^#|^$\" $IP_WHITELISTVSIX | sort | uniq | while read IP
do
    $IPTABLESVSIX -A JANUS_WHITELIST_V6 -s $IP -j ACCEPT
done
            
# Save current configuration to file
if [ ! -d \"" . this->settings->firewall_cfg_folder . "\" ]
then
    mkdir " . this->settings->firewall_cfg_folder . "
fi
$IPTABLES-save > $CONF
$IPTABLESVSIX-save > $CONFVSIX

# Dump the iptables so setting can read them
$IPTABLES -n -L > $DIR/iv4
$IPTABLESVSIX -n -L > $DIR/iv6
"
);
            // Write the migrations.
            this->writeMigrations();
        } catch \Exception, err {
            throw new Exception("Failed to write the cron.sh, " . err->getMessage());
        }
    }

    public function writeMigrations()
    {
        shell_exec("rm " . rtrim(this->settings->cron_folder, "/") . "/migrations/migrations.sh");
        file_put_contents(
            rtrim(this->settings->cron_folder, "/") . "/migrations/migrations.sh",
        "#!/bin/bash
# DO NOT EDIT, AUTOMATICALLY CREATED BY JANUS
# Created on " . date("Y-d-m H:i:s") . "

php -r \"use Janus\\Janus; new Janus('" . this->settings->db_file . "', '" . this->settings->url_key_file . "', false, true);\";"
        );
    }
}