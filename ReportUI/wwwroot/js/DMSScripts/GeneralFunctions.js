function isNull(obj, newValue) {
    if (obj == null || obj == undefined) return newValue;
    else return obj;
}
function GetRequest(str) {
    var Requests = GetAllRequests().split('&');
    for (var x = 0; x < Requests.length; x++) {
        if (Requests[x].substr(0, Requests[x].indexOf('=')) == str)
            return Requests[x].substr(Requests[x].indexOf('=') + 1)
    }
    return -1;
}
function GetAllRequests(pageURL) {
    var URLPath = PageURL();
    if (URLPath.indexOf('?') > 0) {
        return URLPath.substr(URLPath.lastIndexOf('?') + 1);
    }
    return '';
}

function GetJsonGrid(json, gridCols) {
    json = CheckArray(json);
    var cells = [];
    for (var row in json) {
        var obj = [];
        var id;
        for (var datafield in gridCols) {
            if (gridCols[datafield].name !== 'cb' && gridCols[datafield].name !== 'subgrid' && gridCols[datafield].name !== 'rn') {
                if (gridCols[datafield].PK) id = json[row][gridCols[datafield].name];
                value = json[row][gridCols[datafield].name];
                obj.push(value);
                //obj.push(CheckDateFormat(value));
            }
        }
        cells.push({ cell: obj, id: id });
    }
    return cells;
}
function CheckDateFormat(stringDate) {
    if (new RegExp("/Date(.)").test(stringDate)) {
        var d = new Date(parseInt(stringDate.replace("/Date(", "").replace(")/", "")));
        var year = d.getFullYear();
        if (year === 1) { return null; }
        //return d.format("MM/dd/yyyy hh:mm tt");
        return d.format(__DateTimeFormat);
    }
    else
        return stringDate;
}
function BindGridold($grid, Json, Filter) {
    if (Json == -1) {
        $grid.clearGridData();
    }
    var grid = $grid[0];
    var gridjson = {};
    gridjson.rows = GetJsonGrid(Json.Data, grid.p.colModel);
    gridjson.records = Json.RowsCount;
    gridjson.total = (Json.RowsCount > 0 ? Math.ceil(Json.RowsCount / Json.MaximumRows) : 1);
    gridjson.page = parseInt((Json.StartRowIndex) / (grid.p.rowNum) + 1);
    if (grid.p.loadonce == true)
        grid.p.rowNum = gridjson.records;
    if (Filter != null)
        DoFilter($grid, gridjson, Filter);
    else {
        if (gridjson.page > gridjson.total) {
            $grid.setGridParam({ page: gridjson.total }).trigger("reloadGrid");
        }
        else
            grid.addJSONData(gridjson);
    }
}


function DoFilter($grid, gridjson, Filters) {
    var ColumnsFilter, CharSearch;
    CharSearch = Filters.CharSearch.toString().toLowerCase();
    if (Filters.ColumnsFilter != null)
        ColumnsFilter = Filters.ColumnsFilter;
    gridjson.rows = $.grep(gridjson.rows, function (element, index) {
        var bool = true;
        var inSearch = false;
        for (key in element.cell) {
            if (element.cell[key] != null) {
                if (ColumnsFilter != null) {
                    if (!(ColumnsFilter[key] === 'none' || ColumnsFilter[key] === ''))
                        bool = bool && element.cell[key].toString().toLowerCase().indexOf(ColumnsFilter[key].toString().toLowerCase()) > -1;
                }
                inSearch = inSearch || element.cell[key].toString().toLowerCase().indexOf(CharSearch) > -1;
            }
        }
        return bool && inSearch;
    });
    $grid[0].addJSONData(gridjson);
}
function GetGridParameters(JQGrid) {
    var e = JQGrid[0].p.postData;
    var count = Math.ceil(JQGrid[0].p.records / e.rows);
    if (count < e.page) { e.page = count }
    if (e.page == 0) { e.page = 1 }
    return { MaximumRows: e.rows, StartRowIndex: (e.page == 1 ? 0 : (e.page * e.rows - e.rows)), SortExpression: (e.sidx == "" ? "" : (e.sidx + " " + (e.sord).toUpperCase())) };
}
var CurrentURL;
function PageURL() {
    if (CurrentURL === undefined) {
        var URLTEMP = window.document.location.href;
        if (URLTEMP.indexOf('?') != -1)
            CurrentURL = URLTEMP.substr(URLTEMP.substr(0, URLTEMP.indexOf('?')).lastIndexOf('/') + 1);
        else
            CurrentURL = URLTEMP.substr(URLTEMP.lastIndexOf('/') + 1);
        if (CurrentURL.substring(CurrentURL.length - 1, CurrentURL.length) === '#') {
            CurrentURL = CurrentURL.substring(0, CurrentURL.length - 1);
        }
    }
    return CurrentURL;
}
function CallService(MethodName, PostedData, onsuccess) {
    $('#ctl00_UpdateProgress')[0].style.display = "block";
    var httpReguest = $.ajax({
        url: __RootName + "/LocalServices/ClientSideCallAjax.asmx/" + MethodName,
        cache: false,
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        data: JSON.stringify(PostedData),
        async: true,
        type: (PostedData == null ? "GET" : "POST"),
        success: function (responseText) {
            if ($.isFunction(onsuccess))
                onsuccess.call(this, JSON.parse(httpReguest.responseText).d)
        },
        error: function (httpReguest, d, b, c) {
            if (httpReguest.statusText.toLowerCase().indexOf("error") > -1) {
                var Message = JSON.parse(httpReguest.responseText).Message
                if (Message === "SessionLost") {
                    window.location = __RootName + "/Default.aspx";
                    return;
                }
                alert(Message);
                if ($.isFunction(onsuccess))
                    onsuccess.call("", -1);
            }

        }
    });
    //    var Data = JSON.parse(httpReguest.responseText);

    //    if (httpReguest.statusText.toLowerCase().indexOf("error") > -1) {
    //        alert(Data.Message)
    //        return -1;
    //    }
    //    return (JSON.parse(httpReguest.responseText).d);
}

function CreateContextMenu(Options) {
    var $Grid = Options.Grid;
    var $Menu = $('<div></div>').attr('id', $Grid.attr('id') + '_ContextMenu').hide().appendTo(document.body);
    $Menu.addClass('ContextMenu ui-widget ui-widget-content');
    $.each(Options.Controls, function (i, obj) {
        var ctrl = $('#' + obj.ID);
        if (ctrl.length > 0) {
            var span = $('<span></span>').addClass('ui-icon ' + obj.Icon);
            var div = $('<div></div>').addClass('ui-corner-all ContextMenustate')
                    .bind('click', function () { $Menu.hide().css({ left: 0, top: 0 }); ctrl.click(); })
                    .append(span)
                    .append($('<span></span>').text(ctrl.val()))
                    .focus(function () { $(this).addClass('ui-state-active').addClass('ui-state-focus') })
                    .hover(function () { if (!$(this)[0].disabled) $(this).removeClass('ContextMenustate').addClass('ui-state-hover') },
                    function () { if (!$(this)[0].disabled) $(this).addClass('ContextMenustate').removeClass('ui-state-hover') })
            if (ctrl[0].disabled) div.attr('disabled', 'disabled').addClass('ui-state-disabled');
            $Menu.append(div);
        }
    });
    $Menu.bind("contextmenu", function (e) {
        return false;
    });
    var x, y; // event.clientY + document.body.scrollTop
    $(document).bind('mousedown', function (e) {
        x = e.pageX;
        y = e.pageY;
        if (!$.contains($Menu[0], e.target) && e.target != $Menu[0])
            $Menu.hide().css({ left: 0, top: 0 });
        return true;
    });
    $Grid.setGridParam({
        'onRightClickRow': function onRightClickRow(rowid) {
            if ($Grid[0].p.multiselect)
                if (!isSelectedRow(rowid, $Grid))
                    $Grid.setSelection(rowid, true);
            if (document.cookie.indexOf('Local') > -1) {
                if (y + $Menu.height() + 10 > ($(window).height()))
                    $Menu.css({ left: x, top: y - $Menu.height() }).show(300);
                else
                    $Menu.css({ left: x, top: y }).show(300);
            }
            else {
                if (y + $Menu.height() + 10 > ($(window).height()))
                    $Menu.css({ left: x - $Menu.width(), top: y - $Menu.height() }).show(300);
                else
                    $Menu.css({ left: x - $Menu.outerWidth(), top: y }).slideDown(250);
            }
        }
    });
}
function isSelectedRow(rowid, Grid) {
    var rows = Grid.getGridParam("selarrrow");
    for (i in rows) { if (rows[i] == rowid) return true; }
    return false;
}
function isNumberKey(evt) {
    return (event.ctrlKey || event.altKey
                    || (47 < event.keyCode && event.keyCode < 58 && event.shiftKey == false)
                    || (95 < event.keyCode && event.keyCode < 106)
                    || (event.keyCode == 8) || (event.keyCode == 9)
                    || (event.keyCode > 34 && event.keyCode < 40)
                    || (event.keyCode == 46))
}

function BindDetailsGrid($grid, Json) {

    if (Json == -1 || Json == null) {

        $grid.clearGridData();
    }
    var grid = $grid[0];
    var gridjson = {};
    gridjson.rows = GetJsonGrid(Json, grid.p.colModel);
    gridjson.records = Json.length;
    gridjson.total = (Json.RowsCount > 0 ? Math.ceil(Json.length / Json.MaximumRows) : 1);
    gridjson.page = parseInt((Json.StartRowIndex) / (grid.p.rowNum) + 1);

    if (grid.p.loadonce == true)
        grid.p.rowNum = gridjson.records;

    if (gridjson.page > gridjson.total) {
        $grid.setGridParam({ page: gridjson.total }).trigger("reloadGrid");
    }
    else
        grid.addJSONData(gridjson);

}

$.fn.DisableDDL = function (isDisable) {
    if (isDisable) $(this).attr("disabled", "disabled");
    else $(this).removeAttr("disabled");
    $(this).selectmenu("destroy").selectmenu({ style: "dropdown" });
    return $(this);
}


// drop down list methods, you can call them as: $("jqslector").BindDropDownList(...);
$.fn.BindDropDownList = function (data, dataTextField, dataValueField, SelectedValue, ShowNullOption, ShowAllOption) {
    var HTMLOptions = "";
    var ddl = $(this);
    if (!$.isArray(data)) {
        if (data == null)
            data = [];
        else
            data = [data];
    }
    $.each(data, function (i, obj) {
        HTMLOptions += "<option value='" + obj[dataValueField] + "'>" + obj[dataTextField] + "</option>";
    });
    if (ShowAllOption != null && ShowAllOption != false)
        HTMLOptions = "<option value='" + DropDownListSetting.SelectAllOption[0] + "'>" + DropDownListSetting.SelectAllOption[1] + "</option>" + HTMLOptions;
    if (ShowNullOption != false)//ShowNullOption != null &&
        HTMLOptions = "<option value='" + DropDownListSetting.SelectNullOption[0] + "'>" + DropDownListSetting.SelectNullOption[1] + "</option>" + HTMLOptions;

    ddl.html(HTMLOptions);
    if (SelectedValue != null)
        ddl.val(SelectedValue);
    ddl.selectmenu("destroy").selectmenu({ style: "dropdown" });
    return $(this);
}
$.fn.SetDDLValue = function (SelectedValue) {// useing : $("jqSelector").SetDDLValue
    if (!SelectedValue) {
        SelectedValue = DropDownListSetting.SelectNullOption[0];
    }
    $(this).val(SelectedValue);
    $(this).selectmenu("destroy").selectmenu({ style: "dropdown" });
    return $(this);
}


$.fn.Disable = function (isDisable) {
    if (isDisable)
        $(this).attr("disabled", "disabled").addClass("ui-state-disabled");
    else
        $(this).removeAttr("disabled").removeClass("ui-state-disabled");

    if ($(this).hasClass("DMS-DropDownList"))
        $(this).selectmenu("destroy").selectmenu({ style: "dropdown" });
    return $(this);
}

function CheckArray(obj) {
    if (obj == null)
        return [];
    else if (obj.length == null)
        return [obj];
    return obj;
}
function GetGridSelectedRows(JQGrid) {
    var jasonObject = [];
    if (!JQGrid[0].p.multiselect) {
        var id = JQGrid.getGridParam("selrow");
        if (id != null) {
            var row = JQGrid.getRowData(id)
            row.id = id;
            jasonObject.push(row);
        }
        return jasonObject;
    }
    var m = JQGrid.getGridParam("selarrrow");

    for (var i = 0; i < m.length; i++) {
        var s = JQGrid.getRowData(m[i]);
        s.id = m[i];
        jasonObject.push(s);
    }
    return jasonObject;
}
function filterArray(Arr, DataField, Value) {
    var newarr = [];
    $.each(Arr, function (i, obj) {
        if (obj[DataField] == Value)
            newarr.push(obj);
    });
    return newarr;
}
//var __RootName = "/" + document.location.pathname.split("/")[1];
//var __ControllerName = "/" + document.location.pathname.split("/")[2];
function ReloadPage() {
    ShowHideAjaxLoader(true);
    window.location = window.location.href;
}
function goToView(actionName, controllerName, QueryString) {
    ShowHideAjaxLoader(true);
    window.location.href = __RootName + (!controllerName ? __ControllerName : controllerName) + "/" + actionName + (!QueryString ? "" : "?" + QueryString);
}

//, data:JSON.stringify(ExtraData)

function BindGrid(JQGrid, ActionName, ExtraData) {

    var postData = JQGrid[0].p.postData;
    var _loader = $("#load_" + JQGrid[0].id).hide();
    _loader.show();
    var stringPostData = { GridParameters: JSON.stringify(postData), kok: JSON.stringify(ExtraData) }
    if (ExtraData != null) {
        if (typeof (ExtraData).toString().indexOf('object') > -1)
            stringPostData.ExtraData = JSON.stringify(ExtraData);
        else
            var x = $.extend(stringPostData, ExtraData);
        // stringPostData.ExtraData = ExtraData ;
    }

    CallAction(__ControllerName + "/" + ActionName, stringPostData, function (r) {
        JQGrid[0].addJSONData(r);
        JQGrid.jqGrid('resetSelection');
        _loader.hide();
    }, true);
    //var ddl = $(".ui-pg-selbox", JQGrid[0].p.pager);
    //if (ddl.data("selectmenu") != true) {
    //    ddl.selectmenu({ style: 'dropdown' });
    //}
    if (!JQGrid[0].p.disableSearch && !JQGrid[0].nav && !JQGrid[0].ftoolbar) {
        //JQGrid.jqGrid('navGrid', JQGrid[0].p.pager,
        // { edit: false, add: false, del: false },
        // {},
        // {},
        // {},
        // { multipleSearch: true, multipleGroup: true }
        // );
        //JQGrid.jqGrid('filterToolbar', { stringResult: true });
    }
}
$.fn.serializeObject = function () {
    var array = $(this).serializeArray();
    var newObj = {};
    $.each(array, function (i, obj) {
        newObj[obj.name] = obj.value;
    });
    $(this).find("input.DMS-Checkbox").each(function (i, obj) {
        newObj[$(obj).attr("name")] = $(obj)[0].checked;
    });
    $(this).find("select.DMS-DropDownList").each(function (i, obj) {
        obj = $(obj);
        if ($(obj).attr("_Nullable") != null && $(obj).val() == DropDownListSetting.SelectNullOption[0]) {
            newObj[$(obj).attr("name")] = null;
        }
    });
    return newObj;
}

$.fn.BindForm = function (json) {
    var form = $(this);
    $.each(json, function (key, value) {
        var control;
        control = form.find("input[name='" + key + "']");
        if (control.length > 0 && control.hasClass("DMS-TextBox")) {
            if (value == null)
                control.val("");
            else
                control.val(value);
        }
        control = form.find("input[type='checkbox'][name='" + key + "']");
        if (control.length > 0 && control.hasClass("DMS-Checkbox")) {
            if (value == true)
                control.attr("checked", value);
            else
                control.removeAttr("checked");
        }
        control = form.find("select[name='" + key + "']");
        if (control.length > 0 && control.hasClass("DMS-DropDownList")) {
            if (value == null)
                control.SetDDLValue("0");
            else
                control.SetDDLValue(value);
        }

    });


}
function CallAction(Action_ControllerName, Data, CallBack, withOutLoader) {
    var PostedData;
    if (Data != null) {
        if ((typeof (Data)).toString().indexOf('object') > -1)
            PostedData = JSON.stringify(Data);
        else
            PostedData = Data;
    }
    if (!withOutLoader)
        ShowHideAjaxLoader(true);

    var ReturnValue;
    var xhr = $.ajax(
        {
            url: (Action_ControllerName.indexOf(__RootName) > -1 ? Action_ControllerName : __RootName + Action_ControllerName),
            cache: false,
            contentType: "application/json; charset=utf-8",
            data: PostedData,
            async: CallBack == null ? false : true,
            type: "POST",
            success: function (r) {
                if (!withOutLoader)
                    ShowHideAjaxLoader(false);
                if (CallBack) {
                    CallBack.call(this, r);
                }
                else {
                    ReturnValue = r;
                }


            },
            error: function (httpReguest, d, b, c) {
                if (!withOutLoader)
                    ShowHideAjaxLoader(false);
                if (httpReguest.statusText.toLowerCase().indexOf("error") > -1) {
                    var json = JSON.parse(httpReguest.responseText);
                    if (json.RedirectUrl) {
                        window.location = json.RedirectUrl;
                        return;
                    }
                    var Message = json.Message;
                    if (Message === "SessionLost") {
                        goToView("Home", "Index");
                        return;
                    }

                    ShowMessage(Message);
                    if ($.isFunction(CallBack))
                        CallBack.call("", -1);
                }

            }
        }
    );
    return ReturnValue;
}
function ShowHideAjaxLoader(DoShow) {
    if (DoShow)
        $('#AjaxLoaderContainer').stop().show();
    else
        $('#AjaxLoaderContainer').fadeOut(500);
}
function SetTheme(element) {
    $(element).find("input[type='submit'],input[type='button']").button();
    $(element).find(".DMS-DropDownList").selectmenu({ style: 'dropdown' });
    $(element).find('input.DMS-TextBox.date').datepicker({ dateFormat: "dd/mm/yy" });
    $(element).find(".DRMS-SearchImage").button({
        icons: { primary: 'ui-icon-search', secondary: null }
    });
    $(element).find(".DMS-TextBox")
        //.css({ "background": "#fff", "color": "#000" })
        .focus(function () {
            $(this).addClass("ui-state-active");
        }).blur(function () {
            $(this).removeClass("ui-state-active");
        });
    $(element).find('#body fieldset').addClass("ui-widget-content ui-corner-all");
}
function CreateMenu() {
    //$('#flyout').addClass("");
    $(".FirstUL").show().find(".level1 .FirstElement").addClass("ui-corner-t" + (dir == 'rtl' ? 'r' : 'l'));
    $('.FirstUL .level1').each(function () {
        if ($(this).find("ul").length > 0) {
            $(this).find("a").first().menu({
                content: ($(this).find("a").first().next()[0].outerHTML),
                flyOut: true,
                callerOnState: 'ui-widget-content',
                nextMenuLink: 'ui-icon-triangle-1-' + (dir == 'rtl' ? 'w' : 'e'),
                positionOpts: {
                    posX: (dir == 'rtl' ? 'left' : 'left'),// based on dir
                    posY: 'bottom',
                    offsetX: 0,
                    offsetY: 0,
                    detectH: false,
                    detectV: false,
                    directionH: (dir == 'rtl' ? 'left' : 'right'),// based on dir
                    directionV: 'down'
                }
            });
            $(this).find("ul").hide();
        }
        else {
            $(this).find("a").first().menu({
                content: "",
                flyOut: true,
                callerOnState: 'ui-widget-content'
            });
        }
    });
}

function __checkBoxClick(obj) {// each checkbox has a hidden field - to be serialized as Model object  
    var checked = obj.checked;
    $(obj).next().val(checked);
}


var Dialogs = [];
function ShowDialog(actionUrl, width, height, onClosing, Data, hideCloseButton) {
    var $ = top.$;
    var index = $(".Dialog").length;
    //id='Dialog" + index + 1 + "'
    //$(".Dialog").hide();

    $("body").append("<div id='dialog_" + index + "' class='Dialog'></div>");
    $("#dialog_" + index).dialog(
        {
            modal: true,
            autoOpen: false,
            resizable: true,
            draggable: true,
            width: (!width ? 700 : width),
            height: (!height ? 400 : height),
            closeOnEscape: true,
            open: function (event, ui) {
                if (hideCloseButton)
                    $(".ui-dialog-titlebar-close", ui.dialog).hide();
            },
            close: function (ev, ui) {
                if (onClosing && $.isFunction(onClosing))
                    onClosing.call(this, $(this).data("ReturnData"));
                //$(this).remove();
            }
        }
        ).dialog("open");

    var framehtml = $("<iframe frameborder='0' width='100%' height='99%'/>");
    if (!Data) {
        framehtml.attr("src", __RootName + "/" + actionUrl);
        $("#dialog_" + index).append(framehtml);
    }
    else {
        var frameid = "frame_" + index;
        framehtml.attr("name", frameid);
        Data.ActionUrl = __RootName + "/" + actionUrl;
        //formhtml.append("<input type='hidden' name ='PostData' value='"+PostedData+"'/>");
        $("#dialog_" + index).append(framehtml);
        $.form(__RootName + "/" + actionUrl, Data, 'POST', frameid).submit();
        //$.form(__RootName + "/Home/TempActionRedirection", Data, 'POST', frameid).submit();

        //framehtml.attr("src", __RootName + "/" + actionUrl);
    }
}

jQuery(function ($) {
    $.extend({
        form: function (url, data, method, target) {
            if (method == null) method = 'POST';
            if (data == null) data = {};

            var form = $('<form>').attr({
                method: method,
                action: url,
                target: target
            }).css({
                display: 'none'
            });

            var addData = function (name, data) {
                if ($.isArray(data)) {
                    for (var i = 0; i < data.length; i++) {
                        var value = data[i];
                        addData(name + '[]', value);
                    }
                } else if (typeof data === 'object') {
                    for (var key in data) {
                        if (data.hasOwnProperty(key)) {
                            addData(name + '[' + key + ']', data[key]);
                        }
                    }
                } else if (data != null) {
                    form.append($('<input>').attr({
                        type: 'hidden',
                        name: String(name),
                        value: String(data)
                    }));
                }
            };

            for (var key in data) {
                if (data.hasOwnProperty(key)) {
                    addData(key, data[key]);
                }
            }

            return form.appendTo('body');
        }
    });
});

function __CloseDialog(ReturnData) {
    if (ReturnData)
        $(".Dialog").last().data("ReturnData", ReturnData).dialog("close")
    else
        $(".Dialog").last().dialog("close");
    //$(".ui-dialog-titlebar-close").trigger("click")
}
function __ChangeDialogTitle(title) {
    $(".Dialog").last().dialog('option', 'title', title);
}
function CloseDialog() {
    //$(".Dialog").last().dialog("close");
    $(this).last().dialog("close");
    //$(".ui-dialog-titlebar-close").trigger("click")
}
function GetTreeDataFormat(JsonArr, idKey, titleKey, childrenKey, selectedIDs, IsChildMode) {
    var TreeArr = [];
    if (!$.isArray(JsonArr)) {
        JsonArr = [JsonArr];
    }
    for (var x = 0; x < JsonArr.length; x++) {
        var obj = JsonArr[x];
        var TreeObj = {
            key: obj[idKey],
            title: obj[titleKey]
        };
        if (obj[childrenKey] != null && obj[childrenKey].length > 0) {
            TreeObj.children = GetTreeDataFormat(obj[childrenKey], idKey, titleKey, childrenKey, selectedIDs, IsChildMode);
            if (!IsChildMode)
                TreeObj.isFolder = true;
            TreeObj.expand = false;
        }
        else if (($.inArray(obj[idKey], selectedIDs, 0)) > -1) {
            TreeObj.select = true;
        }
        TreeArr.push(TreeObj);
    }
    return TreeArr;
}
function ShowMessage(MessageText, callBack, widthPercent) {
    var $ = top.$;
    var messageDiv = $("#MessagesDialog");
    var optionsObj = {
        modal: true,
        autoOpen: false,
        buttons: [
                {
                    text: "OK",
                    click: function () {

                        $(this).dialog("close");
                        if ($.isFunction(callBack))
                            callBack();
                    }
                }
        ],
        close: function (ev, ui) {
            if ($.isFunction(callBack))
                callBack();
        }
    };

    if (typeof widthPercent != 'undefined' && widthPercent != null && widthPercent > 0 && widthPercent <= 100) {
        optionsObj.width = $(window).width() * (widthPercent / 100.00);
    }

    messageDiv.dialog(optionsObj).data("initialized", true).html(MessageText).dialog("open");
}


function ShowConfirm(MessageText, callBack) {
    var messageDiv = $("#MessagesDialog");
    messageDiv.dialog({
        modal: true,
        autoOpen: false,
        buttons: [
            {
                text: "Yes",
                click: function () {
                    $("#IsConfirmed").val("true");
                    $(this).dialog("close");
                    if ($.isFunction(callBack))
                        callBack(true);
                }
            },
            {
                text: "No",
                click: function () {
                    $("#IsConfirmed").val("false");
                    $(this).dialog("close");
                }
            }
        ]
        //buttons: {
        //    "OK": function () {
        //        $("#IsConfirmed").val("true");
        //        $(this).dialog("close");
        //        if ($.isFunction(callBack))
        //            callBack(true);
        //    },
        //    "Cancel": function () {
        //        $("#IsConfirmed").val("false");
        //        $(this).dialog("close");
        //    }
        //}
    }).text(MessageText).dialog("open");
}

function GetWaitingElement() {

    return "<span class='WaitingElement'></span>";

}
function SetTreeSelection(TreeObj, SelectedKeys) {
    var tree = TreeObj.dynatree("getTree");
    // to remove selection
    var SelectedNodes = tree.getSelectedNodes(false);
    $.each(SelectedNodes, function (i, node) {
        node.select(false);
    });
    SelectedKeys = CheckArray(SelectedKeys);
    $.each(SelectedKeys, function (i, key) {
        var node = tree.getNodeByKey(key);
        node.select(true);
    });
}

function _submitForm(_objbtn) {
    var _e = {};
    $_objbtn = $(_objbtn);
    var _successMessage = $(_objbtn).attr("_successMessage");

    var _onClick = $(_objbtn).attr("_onClick");
    var _afterError = $(_objbtn).attr("_onError");
    var _afterSuccess = $(_objbtn).attr("_onSuccess");

    var _returnView = $(_objbtn).attr("_returnView");
    var _returnController = $(_objbtn).attr("_returnController");
    var _viewName = $(_objbtn).attr("_viewName");
    var _controllerName = $(_objbtn).attr("_controllerName");
    var _confirmMessage = $(_objbtn).attr("_confirmMessage");
    var _causeValidation = $(_objbtn).attr("_causeValidation");

    _e.form = $_objbtn.closest("form");
    _e.model = _e.form.serializeObject();
    _e.response = null;
    _e.error = null;
    _e.showErrorMessage = true;

    if (_e.form.length > 0) {
        _e.url = _e.form.attr("action");
    }
    if (_causeValidation == "false" || _e.form.length == 0)
        _e.valid = true;
    else
        if (_e.form.length > 0)
            _e.valid = _e.form.valid();

    if (_viewName) {
        _e.url = (!_controllerName ? __ControllerName : _controllerName) + "/" + _viewName;
    }

    if (_onClick != null && _e.valid) {/// no calling when the form is not valid
        if (_onClick.indexOf("(") > -1) eval(_onClick);
        else {
            var doSubmit = window[_onClick](_objbtn, _e);
            if (doSubmit === false) return false;
        }
    }
    if (!_e.valid) return false;

    if (_causeValidation != "false") {
        _e.form.bind("submit", function () {
            return false;
        }).submit();
        var formModel = _e.form.serializeObject();
        $.extend(_e.model, _e.model, formModel);
    }

    function IfConfirm() {
        CallAction(_e.url, _e.model, function (response) {

            if (response == -1 && _afterError != null) {
                if (_afterError.indexOf("(") > -1)
                    eval(_afterError);
                else
                    window[_afterError](_objbtn, _e);
            }
            if (_afterSuccess != null && _successMessage == null && response != -1) {
                if (_afterSuccess.indexOf("(") > -1)
                    eval(_afterSuccess);
                else
                    window[_afterSuccess](response);
            }


            if (response == "" || response == null) {
                _e.response = response;
                //ShowMessage('@Resources.Messages.Jobs_SavedSuccesfully');
                if (_successMessage) {
                    ShowMessage(_successMessage, function () {
                        if (_afterSuccess != null) {
                            if (_afterSuccess.indexOf("(") > -1) eval(_afterSuccess);
                            else {
                                window[_afterSuccess](_objbtn, _e);
                            }
                        }
                        if (_returnView != null)
                            goToView(_returnView, _returnController);

                    });
                }
                else if (_returnView != null)
                    goToView(_returnView, _returnController);
            }
            else {
                if (response.Message)
                    ShowMessage(response.Message);
            }
        });
    }

    if (_confirmMessage)
        ShowConfirm(_confirmMessage, IfConfirm);
    else IfConfirm();
}


function _onSearch(_objbtnId) {
    var _e = {};
    $_objbtn = $("#" + _objbtnId);
    var _OnSearch = $_objbtn.attr("_OnSearch");
    var _AfterSearch = $_objbtn.attr("_AfterSearch");
    var _viewName = $_objbtn.attr("_viewName");
    var _controllerName = $_objbtn.attr("_controllerName");
    var _DataValueField = $_objbtn.attr("_DataValueField");
    var _DataTextField = $_objbtn.attr("_DataTextField");
    var _DialogWidth = $_objbtn.attr("_DialogWidth");
    var _DialogHeight = $_objbtn.attr("_DialogHeight");

    _e.Param = {};
    _e.Param.ActionName = _viewName;
    _e.Param.DataValueField = _DataValueField;
    _e.Param.DataTextField = _DataTextField;

    if (_OnSearch != null && _e.valid) {/// no calling when the form is not valid
        if (_OnSearch.indexOf("(") > -1) eval(_OnSearch);
        else {
            var doSubmit = window[_OnSearch]($_objbtn[0], _e);
            if (doSubmit === false) return false;
        }
    }
    var actionUrl = "Search/Index/" + _viewName;
    if (_controllerName != null) {
        actionUrl = _controllerName + "/" + _viewName;
    }
    if (actionUrl.indexOf("?") === -1)
        actionUrl += "?";
    else
        actionUrl += "&";

    for (var name in _e.Param) {
        actionUrl += name + "=" + _e.Param[name] + "&";
    }
    actionUrl = actionUrl.substr(0, actionUrl.length - 1);

    var parent = $_objbtn.parent();
    var txt = parent.find("input.DMS-TextBox");
    var hdn = parent.find("input.DMS-Hidden");

    ShowDialog(actionUrl, _DialogWidth, _DialogHeight, function (data) {
        if (data != null) {
            //var parent = $(_objbtn).parent();
            //var txt = parent.find("input.DMS-TextBox");
            //var hdn = parent.find("input.DMS-Hidden");
            if ((typeof (data)).toString().indexOf("string") > -1 && (data == "" || data.toLowerCase() == "clear")) {
                txt.val("");
                hdn.val("");
            }
            else {
                txt.val(data[_DataTextField]);
                hdn.val(data[_DataValueField]);
            }
        }
    });

}
function onPressEnter(obj, e, eventEnter) {
    if (e.which == 13) {
        eval(eventEnter);
    }
}
function NumericOnly(evt) {
    if (evt.shiftKey)
        return false;
    //alert(evt.keyCode);
    if (((evt.keyCode >= 48) && (evt.keyCode <= 57)) || ((evt.keyCode >= 96) && (evt.keyCode <= 105)))
        return true;
    else {
        if (evt.keyCode == 17 || evt.keyCode == 86) {
            if (evt.ctrlKey) {
                return true;
            }
        }
        //for allowing backspace (8) and delete(46) and left,right arrow and enter btn hit
        if (evt.keyCode == 8 || evt.keyCode == 9 || evt.keyCode == 46 || evt.keyCode == 37 || evt.keyCode == 39 || evt.keyCode == 13 || evt.keyCode == 86)
            return true;
        else
            return false;
    }
}
function AlphabetsOnly(nkey) {
    
    var keyval
    if (navigator.appName == "Microsoft Internet Explorer") {
        keyval = window.event.keyCode;
    }
    else if (navigator.appName == 'Netscape') {
        nkeycode = nkey.which;
        keyval = nkeycode;
    }
    //For A-Z
    if (keyval >= 65 && keyval <= 90) {
        return true;
    }
        //For a-z
    else if (keyval > 105 && keyval <= 122) {
        return true;
    }
        //For Backspace
    else if (keyval == 8 || keyval == 9) {
        return true;
    }
        //For General
    else if (keyval == 0) {
        return true;
    }
        //For Space
    else if (keyval == 32) {
        return true;
    }
    else {
        return false;
    }
}// End of the function

function parseServerDate(srvJsonDate) {
    var date;
    if(srvJsonDate instanceof Date) {
        date = srvJsonDate;
    } else if (!isNaN(parseInt(srvJsonDate))) {
        date = new Date(parseInt(srvJsonDate));
    } else if ((typeof srvJsonDate).toLowerCase() === "string" && srvJsonDate.indexOf("/Date(") == 0) {
        date = new Date(parseInt(srvJsonDate.substring(srvJsonDate.indexOf('(') + 1, srvJsonDate.indexOf(')'))));
    } else {
        return '';
    }
    
    return formatDate(date);
}

function formatDate(date, format) {
    if (date instanceof Date) {
        format = (typeof format == 'undefined') ? 'dd/MM/yyyy' : format;
        var month = date.getMonth() + 1;
        var day = date.getDate();
        var year = date.getFullYear();
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var seconds = date.getSeconds();
        var formatedDate = format
            .replace('dd', digitize(day, 2))
            .replace('MM', digitize(month, 2))
            .replace('yyyy', digitize(year, 4))
            .replace('hh', digitize(hours, 2))
            .replace('mm', digitize(minutes, 2))
            .replace('ss', digitize(seconds, 2));

        return formatedDate;
    } else {
        return '';
    }
}

function parseTimeSpan(timeSpan) {
    if ("Hours" in timeSpan && "Minutes" in timeSpan && "Seconds" in timeSpan) {
        return digitize(timeSpan.Hours, 2) + ":" + digitize(timeSpan.Minutes, 2) + ":" + digitize(timeSpan.Seconds, 2);
    } else {
        return '';
    }
}

function digitize(number, digits) {
    var prefix = '';
    var numLength = number.toString().length;
    if (numLength < digits) {
        for (var i = 0; i < (digits - numLength) ; i++) {
            prefix += '0';
        }
    }
    return prefix + number;
}