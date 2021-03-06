/**
 * app_grid_layout.qml
 *
 * Copyright (C) 2016 Kano Computing Ltd.
 * License: http://www.gnu.org/licenses/gpl-2.0.txt GNU GPL v2
 *
 * Grid for app entries
 */


import QtQuick 2.3
import Kano.Layouts 1.0 as KanoLayouts

import Kano.Apps 1.0 as KanoApps


KanoLayouts.TileGridLayout {
    signal app_launched(string launch_command)
    signal app_hovered(string app)

    property int page_index: 0
    property int page: page_index + 1
    readonly property int app_count: apps_list.apps.length
    readonly property int page_count: Math.ceil(app_count / tile_count)

    property bool ltr: true
    readonly property int page_turn_offset: ltr ? grid.cellWidth / 2 : -grid.cellWidth / 2
    readonly property int page_turn_duration: 75
    property int queued_page: 0

    property var control   // Some KanoApps.AppGridControl

    Binding {
        target: control
        property: 'current_page'
        value: grid.queued_page
    }
    Binding {
        target: control
        property: 'page_count'
        value: grid.page_count
    }
    Binding {
        target: control
        property: 'tile_count'
        value: grid.tile_count
    }
    Binding {
        target: control
        property: 'app_count'
        value: grid.app_count
    }
    Connections {
        target: control

        onChange_page: grid.set_page(page)
    }


    id: grid
    spacing: 0

    offset: page_index * tile_count

    function next_page() {
        set_page(page + 1);
    }

    function previous_page() {
        set_page(page - 1);
    }

    function set_page(page_no) {
        page_no--;
        grid.ltr = page_no < page_index;

        page_no = page_no % page_count;
        if (page_no < 0) {
            page_no = page_count + page_no;
        }

        queued_page = page_no;
        page_change.running = true
    }

    rows: 3
    columns: 3

    KanoApps.InstalledAppList {
        id: apps_list
        property bool initialised: false
        function initialise() {
            if (!initialised && grid.width > 0 && grid.height > 0) {
                apps_list.update()
                initialised = true;
            }
        }
    }
    tile_model: apps_list.apps

    // Rows and columns incorrectly align if the width and height
    // isn't final when they are set
    onWidthChanged: apps_list.initialise()
    onHeightChanged: apps_list.initialise()

    populate: Transition {
        id: pop_trans
        property point dest: pop_trans.ViewTransition.destination
        property bool ltr: true

        ParallelAnimation {
            NumberAnimation {
                property: 'opacity'
                from: 0.0
                to: 1.0
                duration: grid.page_turn_duration
            }
            NumberAnimation {
                properties: 'x'
                from: pop_trans.dest.x - grid.page_turn_offset
                duration: grid.page_turn_duration
            }
        }
    }
    SequentialAnimation {
        id: page_change
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: grid
                property: 'opacity'
                from: 1.0
                to: 0.0
                duration: grid.page_turn_duration
            }
            PropertyAnimation {
                target: grid
                property: 'contentX'
                to: -grid.page_turn_offset
                duration: grid.page_turn_duration
            }
        }
        ParallelAnimation {
            ScriptAction {
                script: grid.page_index = grid.queued_page
            }
            PropertyAnimation {
                target: grid
                property: 'opacity'
                to: 1.0
                duration: 0
            }
        }
    }


    clip: false

    delegate: KanoApps.AppTile {
        app: modelData.title
        launch_command: modelData.launch_command
        image_source: modelData.icon
        height: grid.content_height
        width: grid.content_width
        onApp_launched: grid.app_launched(launch_command)
        onApp_hovered: grid.app_hovered(app)
    }

}
