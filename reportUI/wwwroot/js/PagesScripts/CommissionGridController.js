function ShowCommissionGirdColumns(columnModels, ColumnName, IsDateColumn) {
    ColumnName = ColumnName.replace(" ", "");
    if (IsDateColumn)
        ColumnName = ColumnName + 'Date';
    for (var i = 0; i < columnModels.length; i++) {
        if (columnModels[i].name == ColumnName) {
            columnModels[i].hidden = false;
            if (!IsDateColumn) {
                columnModels[i].formatter = function (cellVal, opt, rowObject) {
                    var value = rowObject.ElementAmounts[opt.colModel.name];
                    return typeof value == 'undefined' || value == null || value.Amount == null ? 0 : value.Amount;
                }
                ShowCommissionGirdColumns(columnModels, ColumnName, true);
            } else {
                columnModels[i].formatter = function (cellVal, opt, rowObject) {
                    var value = rowObject.ElementAmounts[opt.colModel.name];
                    return typeof value == 'undefined' || value == null || value.PayoutDate == null ? 'N/A' : value.PayoutDate;
                }
            }

        }
    }
}
function GetCommissionGirdColumns() {

var columns = [
            "Activation date",
            "First payable event date",
            "Contract collection date",
            "Distribution channel",
            "Activation channel",
            "Distributed by",
            "Activated by",
            "IMSI / Kit code",
            "Primary IMSI",
            "Quality grade",
            "First payable event",
            "Contract collection",
            //Prepaid Only
            "1st Refill",
            "2nd Refill",
            "3rd Refill",
            //Postpaid Only
            "1st Bill Payment",
            "2nd Bill Payment",
            "3rd Bill Payment",
            "End of Year"
];


// columns = [
//                    "Activation date",
//                    "Distribution channel",
//                    "Activation channel",
//                    "Distributed by",
//                    "Activated by",
//                    "IMSI",
//                    "MSISDN",
//                    "Quality Grade",
//                    "First payable event date",
//                    "1st Refill",
//                    "2nd Refill",
//                    "3rd Refill",
//                    "4th Refill",
//                    "5th Refill"

//];
// console.log(columns.length);

return columns;
}

function GetCommissionGirdColumnModels() {
    var columnModels = [
                { name: "ActivationDate", width: 70 },
                { name: "FirstPayableEventDate", width: 90 },
                { name: "ContractCollectionDate", width: 90 },
                { name: "DistributionChannel", width: 70 },
                { name: "SalesChannel", width: 60 },
                { name: "DistributedBy", width: 80 },
                { name: "ActivationDealerCode", width: 90 },
                { name: "ImsiOrKitCode", width: 90 },
                { name: "PrimaryImsi", width: 90 },
                { name: "QualityGrade", width: 60 },
                { name: "FirstPayableEvent", width: 90, hidden: true },
                { name: "ContractCollection", width: 90 },
                //Prepaid Only
                { name: "FirstRecharge", width: 60, hidden: true },
                { name: "SecondRecharge", width: 60, hidden: true },
                { name: "ThirdRecharge", width: 60, hidden: true },
                //Postpaid Only
                { name: "FirstBillPayment", width: 45, hidden: true },
                { name: "SecondBillPayment", width: 45, hidden: true },
                { name: "ThirdBillPayment", width: 45, hidden: true },
                { name: "EndOfYearPayment", width: 45, hidden: true }
    ];


    // columnModels = [
    //        { name: "ActivationDate", width: 60 },
    //        { name: "DistributionChannel", width: 60 },
    //        { name: "SalesChannel", width: 60 },
    //        { name: "DistributedBy", width: 60 },
    //        { name: "ActivationDealerCode", width: 60 },
    //        { name: "ImsiOrKitCode", width: 60 },
    //        { name: "MSISDN", width: 60 },
    //        { name: "ContractCollection", width: 90 },
    //        { name: "FirstPayableEvent", width: 90, hidden: false },
    //        { name: "FirstRecharge", width: 90, hidden: false },
    //        { name: "SecondRecharge", width: 90, hidden: false },
    //        { name: "ThirdRecharge", width: 90, hidden: false },
    //        { name: "FourthRecharge", width: 90, hidden: false },
    //        { name: "FifthRecharge", width: 90, hidden: false }
    //];
     //console.log(columnModels.length);
    return columnModels;
}