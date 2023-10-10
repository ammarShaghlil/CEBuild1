function GeneratedForm(options) {
    var Me = this;
    Me.Options = options || {};

    Me.ddl = $(Me.Options.MainDropDwonListId);
    Me.container = $(Me.Options.ContainerId);
    Me.form = $(Me.Options.FormId);
    Me.hdn = $(Me.Options.SubmitedHiddenField);
    Me.LookupsURL = "Lookup/GetLookupItems";
    Me.LookupNamesURL = "Lookup/GetLookupNames/0";
    Me.OtherValuelbl = "Other Value";
    if (Me.Options.IsSearch) {
        Me.ddlsub = $(Me.Options.SubDropDwonListId);
    }
    Me.AllTemplates = {};
    Me.CurrentTemplate = null;
   
    
    Me.RefreshForm = function () {
        var typeid;
        if (!Me.Options.IsDetailsMode)
            typeid = Me.ddl.val();
        else
            typeid = Me.Options.TypeId;

        if (typeid == "0") {
            Me.container.html("");
            if (Me.Options.IsSearch)
                Me.ddlsub.BindDropDownList([], "", "", null, true);
            return;
        }
        //var params = { TypeId: typeid };

        //CallAction(Me.Options.Url, params, Me.GenerateForm);

        if (Me.AllTemplates[typeid] != null) {
            Me.CurrentTemplate = Me.AllTemplates[typeid];
            if (Me.Options.IsSearch)
                Me.ddlsub.BindDropDownList(Me.CurrentTemplate, "Title", "Name", null, true);
            else
                Me.GenerateForm();
        }
        else {
            var params = { TypeId: typeid };
            CallAction(Me.Options.Url, params, function (data) {
                if (data) {
                    Me.CurrentTemplate = JSON.parse(data.DataTemplate);
                    if (Me.Options.IsSearch)
                        Me.CurrentTemplate = filterArray(Me.CurrentTemplate, "IsSearchable", true);
                    Me.AllTemplates[typeid] = Me.CurrentTemplate;
                }
                if (Me.Options.IsSearch)
                    Me.ddlsub.BindDropDownList(Me.CurrentTemplate, "Title", "Name", null, true);
                else
                    Me.GenerateForm();
            });
        }
    }
    if (!Me.Options.IsDetailsMode)
        Me.ddl.bind("change", Me.RefreshForm);
    Me.RefreshForm();
    if (Me.ddlsub)
        Me.ddlsub.bind("change", function () {
            var CurrentTemplate = Me.CurrentTemplate;
            var msg = '<span class="field-validation-valid" data-valmsg-for="Description" data-valmsg-replace="true"></span>';
            var ctrls = "";
            var selectedTemplate = Me.ddlsub.val();
            if (selectedTemplate != "0") {
                var obj = filterArray(CurrentTemplate, "Name", selectedTemplate)[0];
                var title = CurrentLanguage == Languages.Local ? obj.Title : obj.ForeignTitle;;
                ctrls += Me.GetHtmlCtrl(Me.Options.SubValueFieldName, title, obj.Type, null, Me.Options.LabelsWidth, Me.Options.ControlsWidth, false, false, Me.Options.WrapControls);
            }
            Me.container.html(ctrls);
            SetTheme(Me.container);
            $.data(Me.form[0], 'validator', null);
            $.validator.unobtrusive.parse(Me.Options.FormId);

        });
    if (!Me.ddlsub && !Me.Options.IsDetailsMode)
        Me.form.bind("submit", function () {
            if (!Me.form.valid()) return;
            var object = Me.form.serializeObject();
            var newArr = [];
            for (var i in object) {
                var newObj = {};
                if (i.indexOf("R_") == 0) {
                    var name = i.replace("R_", "");
                    var OtherValue = "";
                    newObj.Name = name;
                    newObj.Value = object[i];
                    if (newObj.Value == DropDownListSetting.SelectOtherOption[0] && $("#RO_" + name).length > 0)
                        newObj.OtherValue = $("#RO_" + name).val();

                    newArr.push(newObj);
                }
                //else if (i.indexOf("RO_") == 0)
                //{
                //    newObj.OtherValue = object[i];
                //}
            }
            $(Me.hdn).val(JSON.stringify(newArr));
        });

    Me.GetHtmlCtrl = function (Name, Title, Type, Value, LabelWidth, ControlWidth, Required, Disabled, WrapControls) {
        var ctrl = "";
        ctrl = '<span class="DMS-ControlContainer">'

        var validationMessage = '<span class="field-validation-valid" data-valmsg-for="' + Name + '" data-valmsg-replace="true"></span>';
        var Label = '<label class="DMS-Label" for="' + Name + '" style="' +
            (LabelWidth ? 'width:' + LabelWidth + 'px' : '') + '" >' + Title + '</label>';
        var RequiredAttr = (Required ? ' data-val-required="The ' + Title + ' field is required."' : '');
        var StyleAttr = ' style="' + (ControlWidth ? 'width:' + ControlWidth + 'px' : '') + '" ';
        var DisabledAttr = Disabled ? " disabled='disabled' " : "";
        switch (Type.toLowerCase()) {
            case "boolean":
                {

                    ctrl += '<input data-val="true" class="DMS-Checkbox" id="' + Name + '" name="' + Name + '" type="checkbox" ' + (Value == "true" ? ' checked="checked"' : "") + DisabledAttr + '>';
                    //ctrl += '<input name="' + Name + '" type="hidden" value="' + Value + '">';
                    ctrl += Label;
                    break;
                }
            case "numeric":
                {
                    ctrl += Label;
                    ctrl += '<input class="DMS-TextBox ui-state-default ui-corner-all" data-val="true"' +
                        ' data-val-number="The field ' + Title + ' must be a number."' + RequiredAttr + StyleAttr + DisabledAttr
                        + ' id="' + Name + '" name="' + Name + '" type="text" value="' + (Value || "") + '">'
                    ctrl += validationMessage;
                    break;
                }
            case "ddl":
                {
                    ctrl += Label;
                    ctrl += '<select class="DMS-DropDownList ui-state-default ui-corner-all" data-val="true"' + RequiredAttr + StyleAttr + DisabledAttr
                    + ' id="' + Name + '" name="' + Name + '" type="text" value="' + (Value || "") + '">'
                    + '<option value="' + DropDownListSetting.SelectNullOption[0] + '">' + DropDownListSetting.SelectNullOption[1] + '</option>'
                    + '</select>';
                    ctrl += validationMessage;
                    //SelectAllOption: ["-2", CommonResources.SelectAll]
                    break;
                }
            case "text":
                {
                    ctrl += Label;
                    ctrl += '<input class="DMS-TextBox ui-state-default ui-corner-all" data-val="true"' + RequiredAttr + StyleAttr + DisabledAttr
                    + ' id="' + Name + '" name="' + Name + '" type="text" value="' + (Value || "") + '">'
                    ctrl += validationMessage;
                    break;
                }
            case "date":
                {
                    ctrl += Label;
                    ctrl += '<input class="DMS-TextBox ui-state-default ui-corner-all date" data-val="true"' +
                        ' data-val-date="The field ' + Title + ' must be a date."' + RequiredAttr + StyleAttr + DisabledAttr
                        + ' id="' + Name + '" name="' + Name + '" type="text" value="' + (Value || "") + '">'
                    ctrl += validationMessage;
                    break;
                }
            case "label":
                {
                    ctrl += Label;
                    ctrl += "<span id='" + Name + "'>" + (Value || "") + "</span>";

                    break;
                }
        }
        
        ctrl += '</span>'
        if (WrapControls)
            ctrl += '<br/>'
        return ctrl;
    }
    var Lookups = {};
    Me.BindDropDown = function () {


    }
    Me.SetDDLs = function (data) {
        //debugger
        lookupIds = [];
        for (var i in Lookups) {
            if (Me.Options.IsDetailsMode) {
                var lookupid = Lookups[i].TemplateItem.Value;
                if (!lookupid && lookupid.length == 0)
                    return;

                if (lookupid == DropDownListSetting.SelectNullOption[0]) {
                    $("#R_" + i).text("");
                }
                else if (lookupid == DropDownListSetting.SelectOtherOption[0]) {
                    $("#R_" + i).text(Lookups[i].TemplateItem.OtherValue);
                }
                else {
                    lookupIds.push(Lookups[i].TemplateItem.Name + "__" + lookupid);
                }
            }
            else {
                var ddlbtn = $("#R_" + i + "-button");
                ddlbtn.data("i__", i);

                var ddl = $("#R_" + i);
                ddl.data("i__", i);

               

                //ddl.BindDropDownList();
                ddlbtn.bind("click", function () {

                    var ddlbtn = $(this);
                    var i = ddlbtn.data("i__");
                    var ddl = $("#R_" + i);
                    var menu = $("#R_" + i + "-menu");
                    var TemplateItem = Lookups[i].TemplateItem;


                    //if (!menu.hasClass("ui-selectmenu-open")) return false;
                    CallAction(Me.LookupsURL + "/" + TemplateItem.LookupType, null,
                         function (data) {
                             if (data != -1) {


                                 if (TemplateItem.AllowOther) {
                                     //var temp = data.splice(1, data.length - 1, { Id: DropDownListSetting.SelectOtherOption[0], Name: DropDownListSetting.SelectOtherOption[1] });
                                     data.push({ Id: DropDownListSetting.SelectOtherOption[0], Name: DropDownListSetting.SelectOtherOption[1] });
                                 }
                                 var autoclick = $("#R_" + i + "-button").data("autoclick");
                                
                                 ddl.BindDropDownList(data, "Name", "Id", TemplateItem.Value);

                                 if (autoclick != true) {
                                     $("#R_" + i + "-button").trigger("mousedown");
                                 }
                                 if (TemplateItem.OtherValue != null) {
                                     ddl.trigger("change");
                                 }
                             }
                         });
                });
                if (Lookups[i].TemplateItem.Value != null) {
                    ddlbtn.data("autoclick", true).click();
                }
                ddl.change(function () {
                    var ddl = $(this);
                    var i = ddl.data("i__");
                    var TemplateItem = Lookups[i].TemplateItem;

                    if (ddl.val() == DropDownListSetting.SelectOtherOption[0]) {
                        var parent = ddl.closest(".DMS-ControlContainer");
                        var ctrl = Me.GetHtmlCtrl("RO_" + i, Me.OtherValuelbl, "Text", TemplateItem.OtherValue, Me.Options.LabelsWidth, Me.Options.ControlsWidth, true, false, true);


                        $(ctrl).insertAfter(parent)
                    }
                    else {
                        //$("#RO_" + i).closest(".DMS-ControlContainer").remove();
                        $("#RO_" + i).closest(".DMS-ControlContainer").next().remove();
                        $("#RO_" + i).closest(".DMS-ControlContainer").remove();
                    }

                });
              
            }

        }
        if (lookupIds.length>0)
            CallAction(Me.LookupNamesURL, { lookupIds: lookupIds.join(",") },
            function (data) {
                $.each(data, function (i, obj) {
                    $("#R_" + obj.Key).text(obj.Name);
                });
            });
        
    }
    Me.GenerateForm = function GenerateForm(data) {
        var DataTemplate =CheckArray( Me.CurrentTemplate);
        var ctrls = "";
        var currentData;
        if ($(Me.hdn).val().length > 0)
            currentData = JSON.parse($(Me.hdn).val());
        
        $.each(DataTemplate, function (i, obj) {
            if (currentData != null && currentData.length > 0) {
                var assetObj = filterArray(currentData, "Name", obj.Name);
                if (assetObj.length > 0) {
                    obj.Value = assetObj[0].Value;
                    obj.OtherValue = assetObj[0].OtherValue;
                }
            }
            var ctrlType = obj.Type.toLowerCase();

            var title = CurrentLanguage == Languages.Local ? obj.Title : obj.ForeignTitle;
            if (ctrlType == "ddl") {
                Lookups[obj.Name] = { TemplateItem: obj, Data: null };
            }

            var Disabled = false;
            if (Me.Options.IsDetailsMode) {
                if (obj.Type == "boolean") {
                    Disabled = true;
                }
                else {
                    ctrlType = "label";
                }
            }
           
            ctrls += Me.GetHtmlCtrl("R_" + obj.Name, title, ctrlType, obj.Value, Me.Options.LabelsWidth, Me.Options.ControlsWidth, obj.IsMandatory, Disabled, Me.Options.WrapControls);
        });
        Me.container.html(ctrls);
        SetTheme(Me.container);


        Me.SetDDLs();



        // to reset form validation
        if (Me.form.length > 0) {
            $.data(Me.form[0], 'validator', null);
            $.validator.unobtrusive.parse(Me.Options.FormId);
        }
    }
    //ctrls = '<span class="DMS-ControlContainer"><label class="DMS-Label ui-state-default" for="ContactNumber1" style="">ContactNumber1</label><input class="DMS-TextBox ui-state-default ui-corner-all" data-val="true" data-val-required="The ContactNumber1 field is required." id="ContactNumber1" name="ContactNumber1" style="" type="text" value="10/10/2012" /><span class="field-validation-valid" data-valmsg-for="ContactNumber1" data-valmsg-replace="true"></span></span>';
}