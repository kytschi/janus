/**
 * Janus head builder
 *
 * @package     Janus\Ui\Head
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
namespace Janus\Ui;

class Head
{
    public function build()
    {
        return "
            <head>
                <title>Janus</title>
                <script src='/assets/chartjs.min.js'></script>
                <link rel='icon' type='image/png' sizes='64x64' href='/assets/janus.png'> " .
                this->style() . "
            </head>";
    }

    private function style()
    {
        return "<style>
        :root {
            /* Body */
            --body-background-colour: #92ddd6;
            --body-text-colour: #221E1F;
        
            /* Box */
            --box-background-colour: #fff;
            --box-success-background-colour: #1FD4AF;
            --box-active-background-colour: #71C2FF;
            --box-deleted-background-colour: #8B8B8B;
            --box-disabled-background-colour: #c2c2c2;
            --box-warning-background-colour: #F08966;
            --box-border-colour: #221E1F;
            --box-title-background-colour: #FDEA00;
            --box-title-border-colour: #221E1F;
            --box-shadow: rgba(0, 0, 0, 0.1) 0px 20px 25px -5px, rgba(0, 0, 0, 0.04) 0px 10px 10px -5px;
        
            /* Buttons */
            --button-background-colour: #63B0CA;
            --button-background-colour-disabled: #c9c9c9;
            --button-hover-background-colour: #D49045;
            --button-border-colour: #221E1F;
            --button-svg-fill-colour: #221E1F;
            --button-text-colour: #221E1F;
            --button-shadow: rgba(0, 0, 0, 0.1) 0px 20px 25px -5px, rgba(0, 0, 0, 0.04) 0px 10px 10px -5px;
        
            /* Inputs */
            --input-border-colour: #221E1F;
            --input-border-focus-colour: #D49045;
        
            /* Text */
            --text-heading-background-colour: #FDEA00;
            --text-heading-colour: #221E1F;
            --text-heading-border-colour: #221E1F;
            --text-heading-shadow: rgba(0, 0, 0, 0.1) 0px 20px 25px -5px, rgba(0, 0, 0, 0.04) 0px 10px 10px -5px;
            --text-required-colour: #221E1F;
            --text-disabled: #a2a2a2;
            --text-deleted: #f44f46;
        }
        
        /* Fonts */
        html, body {
            color: var(--body-text-colour);
            background-color: #D4813F;
            font-family: Helvetica, sans-serif;
            height: 100vh;
            width: 100%;
            margin: 0;
            padding: 0;
            overflow-x: hidden;
            font-size: 14pt;
        }
        body {
            display: flex;
            flex-direction: row;
            align-items: flex-start;
            width:100%;
            overflow-x: hidden;
            background-image: url('/assets/janus-bk.jpg');
            background-position: center center;
            background-repeat: no-repeat;
            background-size: 100% auto;
        }
        a, a:hover, a:visited {
            color: var(--body-text-colour);
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .button:hover, .mini:hover {
            text-decoration: none;
        }  
        main {
            position: relative;
            margin: 0 auto;
            width: 100%;
            max-width: 1200px;
            z-index: 2;
            padding: 60px 0px;
            display: flex;
            flex-direction: column;
        }

        pre {
            white-space: pre-wrap;       /* Since CSS 2.1 */
            white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
            white-space: -pre-wrap;      /* Opera 4-6 */
            white-space: -o-pre-wrap;    /* Opera 7 */
            word-wrap: break-word;       /* Internet Explorer 5.5+ */
        }        

        /* Inputs */
        input, textarea, select {
            padding: 10px;
            width: calc(100% - 20px);
        }
        input:focus, textarea:focus, select:focus {
            border:1px solid var(--input-border-focus-colour);
            outline: none;
            box-shadow: none;
            -moz-box-shadow: none;
            -webkit-box-shadow: none;
        }
        .switcher {
            font-size: 0pt !important;
        }
        .switcher label * {
            vertical-align: middle;
            overflow: hidden;
        }
        .switcher input {
            display: none;
        }
        .switcher label input + span {
            position: relative;
            display: inline-block;
            margin-right: 10px;
            width: 100px;
            height: 38.2px;
            background-color: var(--box-background-colour);
            border:1px solid var(--input-border-colour);
            transition: all 0.3s ease-in-out;
        }
        .switcher label input + span small {
            position: absolute;
            display: block;
            width: 50%;
            height: 100%;
            overflow: hidden;
            cursor: pointer;
            background-color: var(--button-background-colour-disabled);
            transition: all .15s ease;
            box-shadow: none;
            font-size: 12px;
            font-weight: 600;
            text-align: center;
            user-select: none;
        }
        .switcher label input:checked + span {
            background-color: var(--box-background-colour);
        }
        .switcher label input:checked + span small {
            background-color: var(--button-background-colour);
            left: 50%;
        }
        .switcher label input:checked + span .switcher-off {
            display: none;
        }
        .switcher label input:checked + span .switcher-on {
            display: block;
        }

        /* Buttons */
        button, .button-blank, .button  {
            color: var(--button-text-colour);
            font-family: Helvetica, sans-serif;
            font-weight: bold;
            font-size: 14pt;
            text-transform: capitalize;
            background-color: var(--button-background-colour);
            border: 3px solid var(--button-border-colour);
            cursor: pointer;
            text-decoration: none;
            line-height: 20px;
            padding: 20px 20px 10px 20px;
        }
        .button-blank {
            background: none !important;
            border: 0 !important;
        }
        button:hover, .button:hover {
            background-color: var(--button-hover-background-colour);
        }
        .button-blank:hover {
            color: var(--button-hover-background-colour);
        }
        .round {
            display: block;
            height: 100px !important;
            width: 100px !important;
            border-radius: 50%;
            text-align: center;
            vertical-align: middle;
            padding: 0 !important;
            font-size: 0pt !important;
            background-color: var(--text-heading-background-colour);
            border: 3px solid var(--button-border-colour);
            cursor: pointer;
        }
        .round img {
            margin-top: 20px;
            width: 60px;
        }
        .float-right {
            float: right !important;
        }
        .mini {
            display: block;
            cursor: pointer;
            width: 40px !important;
            height: 40px !important;
            float: left;
            margin-right: 5px;
        }
        .mini.icon::before {
            width: 40px !important;
            height: 40px !important;
            left: 0px !important;
            top: 0px !important;
            background-size: 400px 80px;
            
        }
        .deleted .round, .deleted .button, .deleted button {
            background-color: var(--box-deleted-background-colour);
        }
        .page-toolbar {
            display: flex;
            margin-bottom: 40px;
        }
        .page-toolbar .round {
            margin-right: 20px;
        }
        .page-toolbar .align-right {
            margin-left: auto;
        }

        /* Box */
        .box, .table {
            border: 3px solid var(--box-border-colour);
            box-shadow: var(--box-shadow);
            background-color: var(--box-background-colour);
            margin-bottom: 40px;
            border-collapse: collapse;
            min-width: 50%;
        }
        #login.box {
            width: 50%;
        }
        .alert {
            border: 3px solid var(--box-border-colour);
            box-shadow: var(--box-shadow);
            background-color: var(--box-background-colour);
            margin-bottom: 40px;
            font-weight: bold;
            padding: 20px;
        }
        .row {
            display:flex;
            column-gap: 20px;
        }
        .box-body {
            padding: 20px 20px;
        }
        .box-footer {
            padding: 0 40px 40px 40px;
            display: flex;
            justify-content: flex-end;
        }
        .box-footer a, .box-footer button {
            margin-left: 20px;
        }
        .box-title {
            display: flex;
            flex-direction: row;
        }
        .box-title, .table th, .table td {
            padding: 20px;
            border-bottom: 3px solid var(--box-title-border-colour);
        }
        .box-title, .table th {
            background-color: var(--box-title-background-colour);
            font-weight: bold;
        }
        .table th, .table td {
            text-align: left;
            border-right: 3px solid var(--box-title-border-colour);
        }
        .table tr.deleted {
            color: var(--text-deleted);
            text-decoration: line-through;
        }
        .table tr .blank {
            background-color: var(--box-disabled-background-colour);
        }
        .table tr .total {
            background-color: var(--box-title-background-colour);
            text-align: right;
        }
        .table .buttons {
            text-align: right;
        }
        .table .buttons .mini {
            float: right !important;
        }
        .box-title img {
            width: 80px;
            margin-right: 10px;
        }
        .error .box-body, .success .box-body {
            text-transform: uppercase;
        }
        .error .box-body p, .success .box-body p {
            padding: 0;
            margin: 0;
        }
        .deleted.alert, .deleted .box-title {
            background-color: var(--box-deleted-background-colour);
        }
        .warning.alert {
            background-color: var(--box-warning-background-colour);
        }
        /* Quick menu */
        #quick-menu-button {                
            position: fixed;
            right: 30px;
            top: 30px;
            z-index: 100;
        }
        #quick-menu {
            position: fixed;
            right: 55px;
            top: 140px;
            width: 80px;
            z-index: 101;
        }
        #quick-menu .round, #quick-menu-button .round, .page-toolbar .round {
            display: block;
            height: 100px;
            width: 100px;
            border-radius: 50%;
            text-align: center;
            vertical-align: middle;
            overflow: hidden;
            box-shadow: var(--button-shadow);
        }
        #quick-menu .round, .page-toolbar .round  {
            margin-bottom: 10px;
        }
        #quick-menu img, .page-toolbar img {
            margin-top: 20px;
            width: 60px;
        }
        #quick-menu-button img {
            margin-top: 22px;
            width: 80px;
        }
                       
        /* Text */
        h1, h2, h3, h4, h5, h6 {
            font-family: Helvetica, sans-serif;
            font-size: 22pt;
            margin: 20px 0 50px 0;
        }
        h1 span, h2 span {
            color: var(--text-heading-colour);
            background-color: var(--text-heading-background-colour);
            border: 3px solid var(--text-heading-border-colour);
            margin: 0;
            padding: 20px 20px 10px 20px;
            box-shadow: var(--box-shadow);
        }
        .required {
            padding-top: 10px;
            color: var(--text-required-colour);
        }
        .text-top {
            vertical-align: top;
        }

        /* Sizes */
        .wfull {
            width: 100%;
        }

        /* Icons */
        .icon {
            width: 64px;
            height: 64px;
            position: relative;
        }
        .icon::before {
            content: '';
            position: absolute;
            width: 64px;
            height: 64px;
            left: 20px;
            top: 20px;
            right: 0px;
            bottom: 0px;
            background-image: url('/assets/icons.png?t=" . time () . "');
            background-repeat: no-repeat;
            background-position: 0 0;
        }
        .icon-dashboard::before {
            background-position: 0px 0px;
        }
        .icon-users::before {
            background-position: -64px 0px;
        }
        .icon-settings::before {
            background-position: -128px 0px;
        }
        .icon-scan::before {
            background-position: -192px 0px;
        }
        .icon-logout::before {
            background-position: -256px 0px;
        }
        .icon-edit::before {
            background-position: -320px 0px;
        }
        .mini.icon-edit::before {
            background-position: -200px 0px !important;
        }
        .icon-delete::before {
            background-position: -384px 0px;
        }
        .mini.icon-delete::before {
            background-position: -240px 0px !important;
        }
        .icon-next::before {
            background-position: -448px 0px;
        }
        .icon-prev::before {
            background-position: -512px 0px;
        }
        .icon-blacklist::before {
            background-position: -576px 0px;
        }
        .mini.icon-blacklist::before {
            background-position: -360px 0px !important;
        }
        .icon-whitelist::before {
            background-position: 0px -64px;
        }
        .mini.icon-whitelist::before {
            background-position: 0px -40px !important;
        }
        .icon-patterns::before {
            background-position: -64px -64px;
        }
        .icon-back::before {
            background-position: -128px -64px;
        }
        .icon-logs::before {
            background-position: -192px -64px;
        }
        .icon-add::before {
            background-position: -256px -64px;
        }
        .mini.icon-add::before {
            background-position: -165px -40px !important;
        }
        </style>";
    }

    public function toolbar()
    {
        return "<div class='page-toolbar'>
            <a href='/dashboard' class='round icon icon-dashboard' title='Dashboard'>&nbsp;</a>
            <a href='/scan-warn' class='round icon icon-scan' title='Scan the logs'>&nbsp;</a>
            <a href='/blacklist' class='round icon icon-blacklist' title='Blacklisted IPs'>&nbsp;</a>
            <a href='/whitelist' class='round icon icon-whitelist' title='Whitelisted IPs'>&nbsp;</a>
            <a href='/patterns' class='round icon icon-patterns' title='Scan patterns'>&nbsp;</a>
            <a href='/logs' class='round icon icon-logs' title='Browse the logs'>&nbsp;</a>
            <a href='/settings' class='round icon icon-settings' title='Settings'>&nbsp;</a>
            <a href='/logout' class='round icon icon-logout' title='Logout'>&nbsp;</a>
        </div>";
    }
}