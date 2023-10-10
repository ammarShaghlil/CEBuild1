
var DocumentHandler = function (Options) {
    var op = Options || {
        ProcessId: 30,
        ContainerId: "#List",
        ExistingDocuments: [],
        DetailsMode:false,
        DialogButtonId: "#ShowDocument",
        MandatoryTypes:""
    };
    var Me = this;
    Me.Container = $(op.ContainerId)
    Me.DialogButton = $(op.DialogButtonId);
    Me.DocumentListData = CheckArray(op.ExistingDocuments);
    

    Me.DialogButton.bind("click", function () {
        Me.ShowDocumentDialog();
    });

    Me.ShowDocumentDialog = function () {
        ShowDialog("Document/Index?ProcessId=" + op.ProcessId, 750, 450, Me.DocumentDialogClose);
    }

    Me.RefreshDocumentList = function () {
        if (Me.DocumentListData == null) return;
        var list = $("<ul></ul>");
        $.each(Me.DocumentListData, function (index, result) {
            var DeleteIcon="";
            if (!op.DetailsMode) {
                DeleteIcon = $("<span style='padding:2px;cursor:pointer;display:inline-block;vertical-align:middle'><span class='ui-icon ui-icon-close'></span></span>");
                DeleteIcon.first().bind("click", function () { Me.DeleteDocument(result.Id) });
            }

            list.append(
                $("<li docID='" + result.Id + "'></li>")
                .append("<a href='" + __RootName + "/Document/Download/" + result.Id + "'>" + result.FileName + "</a> - " + result.NameType)
                .append(DeleteIcon)
                );
        });
        Me.Container.html(list);
    }


    Me.DocumentDialogClose = function (recivedData) {
        for (var i in recivedData) {
            if ($.inArray(recivedData[i], Me.DocumentListData))
                Me.DocumentListData.push(recivedData[i]);
        }
        //if(recivedData==null)
        //    $("#DocumentIds").val("");
        //else
        //    $("#DocumentIds").val(recivedData.join(','));
        //$("#DocumentList").append()
        Me.RefreshDocumentList();

    }

    Me.DeleteDocument = function (id) {
        //var id = $(obj).parent().attr("docID");
        for (i in Me.DocumentListData) {
            if (Me.DocumentListData[i].Id == id) {
                Me.DocumentListData.splice(i, 1);
                break;
            }
        }
        Me.RefreshDocumentList();
    }
    Me.GetDocumentIds = function () {
        var documentsIds = "";
        $.each(Me.DocumentListData, function (index, result) {
            documentsIds += result.Id + ",";
        });
        return documentsIds;
        //$("#DocumentIds").val(documentsIds);
    }
    if (Me.DocumentListData.length > 0) {
        Me.RefreshDocumentList();
    }
};

