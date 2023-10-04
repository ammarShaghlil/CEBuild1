var globalHelpers = {
    handleDatePickers: function () {
        if (jQuery().datepicker) {
            $('.date-picker').datepicker({
                rtl: false,
                autoclose: true,
                format: globalResources.formats.Date
            });
        }
    },

    handleColorPicker: function () {
        if (!jQuery().colorpicker) {
            return;
        }
        $('.colorpicker-default').colorpicker({
            format: 'hex'
        });
        $('.colorpicker-rgba').colorpicker();
    },

    //Hint: zoneElementId: 'btnUpload', serverAction: '.../File/Upload', resultHiddenFieldId: 'hdnUploadResult', replaceHiddenFieldId: 'hdnUploadReplacment', previewsContainerId: 'hdnImage', acceptedFiles: 'image/*,application/pdf,.psd'
    initSingleFileUploader: function (zoneElementId, serverAction, resultHiddenFieldId, replaceHiddenFieldId, previewsContainerId, options) {
        //Check Parameters
        if (typeof options == 'undefined') {
            options =
            {
                acceptedFiles: 'image/*',
                templateId: 'single-preview-template',
                callbackFunction: undefined,
                autoProcessQueue: true,
                uploadMultiple: false,
                maxFiles: 1,
                thumbnailWidth: 240,
                thumbnailHeight: 240
            };
        }
        else {
            options.acceptedFiles = (typeof options.acceptedFiles == 'undefined') ? 'image/*' : options.acceptedFiles;
            options.templateId = (typeof options.templateId == 'undefined') ? 'single-preview-template' : options.templateId;
            options.callbackFunction = (typeof options.callbackFunction == 'undefined') ? undefined : options.callbackFunction;
            options.autoProcessQueue = (typeof options.autoProcessQueue == 'undefined') ? true : options.autoProcessQueue;
            options.uploadMultiple = (typeof options.uploadMultiple == 'undefined') ? false : options.uploadMultiple;
            options.maxFiles = (typeof options.maxFiles == 'undefined') ? 1 : options.maxFiles;
            options.thumbnailWidth = (typeof options.thumbnailWidth == 'undefined') ? 240 : options.thumbnailWidth;
            options.thumbnailHeight = (typeof options.thumbnailHeight == 'undefined') ? 240 : options.thumbnailHeight;
        }
        var resultField = $('#' + resultHiddenFieldId);
        var replaceField = $('#' + replaceHiddenFieldId);
        var zoneElement = $('#' + zoneElementId);
        var previewContainer = null;

        if (previewsContainerId != null) {
            previewContainer = $('#' + previewsContainerId);
            previewContainer.addClass('dropzone dropzone-previews');
        }
        //else {
        //    zoneElement.addClass('dropzone');
        //}

        var dropZone = new Dropzone('#' + zoneElementId, {
            url: serverAction,
            autoProcessQueue: options.autoProcessQueue,
            uploadMultiple: options.uploadMultiple,
            acceptedFiles: options.acceptedFiles,
            maxFiles: options.maxFiles,
            previewsContainer: (previewContainer == null) ? null : ("#" + previewsContainerId),
            previewTemplate: $('#' + options.templateId).html(),
            thumbnailWidth: options.thumbnailWidth,
            thumbnailHeight: options.thumbnailHeight
        });

        //Events
        dropZone.on("success", function (file, result) {
            if (result.IsAllSucceeded == true && result.UploadedFiles != null && result.UploadedFiles.length > 0) {
                if (resultField.val().length > 0 && resultField.val().split(';')[0].indexOf('/') > -1) {
                    replaceField.val(resultField.val());
                }
                resultField.val(JSON.stringify(result.UploadedFiles));
                if (options.callbackFunction)
                    options.callbackFunction(file, result);
            }
            else {
                this.removeAllFiles();
                resultField.val('');
                alert(result.Message);
            }
        });

        dropZone.on("maxfilesexceeded", function (file) {
            //Replace the file
            this.removeAllFiles();
            this.addFile(file);
        });

        dropZone.on("error", function (file, msg, xhr) {
            var isMaxFilesExceeded = (this.options.maxFiles != null) && this.getAcceptedFiles().length >= this.options.maxFiles;
            var isInvalidFileType = !Dropzone.isValidFile(file, options.acceptedFiles);
            var isFileTooBig = file.size > this.options.maxFilesize * 1024 * 1024;
            this.removeFile(file);
            if (isInvalidFileType || isFileTooBig) {
                bootbox.alert(msg);
            }
        });

        dropZone.on("sending", function (file, xhr, formData) {
            if (resultField.val() != '' && resultField.val().length > 0) {
                formData.append("removedFiles", JSON.parse(resultField.val()));
            }
        });

        var bindStoredImages = function () {
            var existingImagesJsonString = resultField.val();
            if (existingImagesJsonString != null && existingImagesJsonString.length > 0) {
                var existingImages = JSON.parse(existingImagesJsonString);
                if (existingImages != null) {
                    for (var i = 0; i < existingImages.length; i++) {
                        var item = existingImages[i];
                        var file = {
                            name: "Image " + (i + 1),
                            accepted: true,
                            processing: true,
                            status: "success"
                        };

                        dropZone.files.push(file);
                        dropZone.emit("addedfile", file); // And optionally show the thumbnail of the file:
                        dropZone.emit("thumbnail", file, item.split(';')[0]);
                        dropZone.emit("complete", file);
                    }
                }
            }
        }

        bindStoredImages();
    },

    initializeBootbox: function () {
        bootbox.addLocale("localizedTexts",
                {
                    OK: globalResources.commands.Ok,
                    CANCEL: globalResources.commands.Cancel,
                    CONFIRM: globalResources.commands.Confirm
                });
        bootbox.setLocale("localizedTexts");
    },

    showMessage: function (message, title) {
        title = (typeof title != 'undefined' && title.length > 0) ? title : 'Notification';
        bootbox.alert({
            message: message,
            title: angular.element('<span stylDDe="color:#20447d; font-weight:bold;" class="glyphicon glyphicon-info-sign" aria-hidden="true"></span> <b>' + title + '</b>')
        });
    },

    transformDotNetListResponse: function(data){
        if (data != null && (data instanceof Array) && data.length > 0) {
            for(var i in data) {
                globalHelpers.transformDotNetObjectResponse(data[i]);
            }
        }
    },

    transformDotNetObjectResponse: function (data) {
        if (data != null && !(data instanceof Array) && (data instanceof Object)) {
            for (var p in data) {
                if (!data.hasOwnProperty(p)) continue;
                if ((typeof data[p]).toLowerCase() === "string" && data[p].indexOf("/Date(") == 0) {
                    data[p] = moment(data[p]).toDate();
                } else if (data[p] instanceof Array) {
                    globalHelpers.transformDotNetListResponse(data[p]);
                } else if (data[p] instanceof Object) {
                    globalHelpers.transformDotNetObjectResponse(data[p]);
                }
            }
        }
    }
};

Date.prototype.toString = function () {
    return moment(this).format(globalResources.formats.NGDatePicker);
};