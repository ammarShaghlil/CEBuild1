    
  
// to convert from database format to tree format

//function GetTreeDataFormat(JsonArr, idKey, titleKey, childrenKey,selectedIDs) {
//    var TreeArr = [];
//    JsonArr = CheckArray(JsonArr);

//    for (var x = 0; x < JsonArr.length; x++) {
//        var obj = JsonArr[x];
//        var TreeObj = {
//            key: obj[idKey],
//            title: obj[titleKey]
//        };
//        //                
//        if (obj[childrenKey]!=null && obj[childrenKey].length>0) {
                    
//            TreeObj.children = GetTreeDataFormat(obj[childrenKey], idKey, titleKey, childrenKey,selectedIDs);
//            TreeObj.isFolder = true;
//            TreeObj.expand = false;
//        }
//        else if (($.inArray(obj[idKey], selectedIDs, 0)) > -1) {
//            var TreeObj = {
//                key: obj[idKey],
//                title: obj[titleKey],
//                icon: "../../../images/LeafNode.gif",
//                select: true
//            };
//        }
//        else {
//            var TreeObj = {
//                key: obj[idKey],
//                title: obj[titleKey],
//                icon: "../../../images/LeafNode.gif"
//            };
//        }
//        TreeArr.push(TreeObj);
//    }
//    return TreeArr;
//}
var TreeCreator = function (data, selectedIDs, hideCheckBox, onSelectFunction, treeID, RegionPropertyName, HiddenFieldID) {

    var $this = this;
    var __Tree;
    $this.Create = function () {
        // to intialize tree
        if (RegionPropertyName) RegionPropertyName = "Lookup1";
        if (!selectedIDs) selectedIDs = [];

        __Tree = $("#" + treeID).dynatree({
            fx: { height: "toggle", duration: 300 },
            checkbox: !hideCheckBox,
            selectMode: 3,
            onDblClick: function (node, event) {
                if (node.getEventTargetType(event) == "title") node.toggleSelect();
            },
            onKeydown: function (node, event) {
                if (event.which == 32) { node.toggleSelect(); return false; }
            },
            children: GetTreeDataFormat(data, "Id", "Name", RegionPropertyName, selectedIDs)
            ,onSelect: onSelectFunction

        });


        $('span.dynatree-node a')
       .live('mouseover', function () {
           $(this).addClass('ui-state-hover');
       })
       .live('mouseout', function () {
           $(this).removeClass('ui-state-hover');
       });


        return $this;
    }

    function CreateTree(divName1, divName2, data, Businessdata, selectedIDs, hideCheckBox, onSelectFunction, Mandatory) {
        // to intialize tree
        if (!selectedIDs) selectedIDs = [];
        
        divName1 = "#" + divName1.id;
        divName2 = "#" + divName2.id;
        $Tree = $(divName1).dynatree({
            fx: { height: "toggle", duration: 300 },
            checkbox: !hideCheckBox,
            selectMode: 3,
            onDblClick: function (node, event) {
                if (node.getEventTargetType(event) == "title") node.toggleSelect();
            },
            onKeydown: function (node, event) {
                if (event.which == 32) { node.toggleSelect(); return false; }
            },
            children: GetTreeDataFormat(data, "Id", "Name", "Lookup1", selectedIDs),
            onSelect: onSelectFunction

        });

        $businessTree = $(divName2).dynatree({
            fx: { height: "toggle", duration: 300 },
            checkbox: !hideCheckBox,
            selectMode: 3,
            onDblClick: function (node, event) {
                if (node.getEventTargetType(event) == "title") node.toggleSelect();
            },
            onKeydown: function (node, event) {
                if (event.which == 32) { node.toggleSelect(); return false; }
            },
            children: GetTreeDataFormat(data, "Id", "Name", "Lookup1", selectedIDs),
            onSelect: onSelectFunction

        });


        $('span.dynatree-node a')
       .live('mouseover', function () {
           $(this).addClass('ui-state-hover');
       })
       .live('mouseout', function () {
           $(this).removeClass('ui-state-hover');
       });
    }
    //function GetSelectedRegionsBySpecificDiv(id) {
    //    if (id == 1) {
    //        var tree = $Tree.dynatree("getTree");
    //        var SelectedNodes = tree.getSelectedNodes(false);
    //        var selectedIds = [];
    //        $.each(SelectedNodes, function (i, node) {
    //            if (node.hasChildren() === false) {
    //                selectedIds.push(node.data.key);
    //            }
    //        });
    //        return selectedIds;
    //    }
    //    else {
    //        var tree = $businessTree.dynatree("getTree");
    //        var SelectedNodes = tree.getSelectedNodes(false);
    //        var selectedIds = [];
    //        $.each(SelectedNodes, function (i, node) {
    //            if (node.hasChildren() === false) {
    //                selectedIds.push(node.data.key);
    //            }
    //        });
    //        return selectedIds;
    //    }
    //}

    $this.GetSelectedRegions = function () {
        var __tree = __Tree.dynatree("getTree");
        var SelectedNodes = __tree.getSelectedNodes(false);
        var selectedIds = [];
        $.each(SelectedNodes, function (i, node) {
            if (node.hasChildren() === false) {
                selectedIds.push(node.data.key);
            }
        });
        return selectedIds;
    }
    $this.SetSelectedRegions = function () {
        var __tree = __Tree.dynatree("getTree");
        var SelectedNodes = __tree.getSelectedNodes(false);
        var selectedIds = [];
        $.each(SelectedNodes, function (i, node) {
            if (node.hasChildren() === false) {
                selectedIds.push(node.data.key);
            }
        });
        $('#' + HiddenFieldID).val(selectedIds);

    }

    //return $this;
};