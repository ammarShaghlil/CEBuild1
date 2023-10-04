// AngularJS App initializer for .Net MVC solutions :: By Ayyoub Jadoo
(function () {
    if (typeof app == 'undefined') {
        app = angular.module('app', ['cgBusy', 'ui.bootstrap.datetimepicker', 'angularjs-dropdown-multiselect']);

        app.config(['$httpProvider', function ($httpProvider) {
            $httpProvider.defaults.transformResponse.push(function (data) {
                if (data instanceof Array) {
                    globalHelpers.transformDotNetListResponse(data);
                } else if (data instanceof Object) {
                    globalHelpers.transformDotNetObjectResponse(data);
                }

                return data;
            });
        }]);

        //Configs and default values
        app.value('cgBusyDefaults', {
            message: 'Loading...',
            backdrop: true,
            delay: 0,
            minDuration: 2000
        });

        //Common Filters
        app.filter('jsonDate', function ($filter) {
            return function (input, format) {
                if (input != null) {
                    format = (typeof format == 'undefined' || format == null) ? globalResources.formats.AngularDate : format;
                    if (input instanceof Date) {
                        return $filter('date')(input, format);
                    } else {
                        //Handle dotNet serialized dates in /Date(1330848000000)/ format
                        return $filter('date')(parseInt(input.substr(6)), format);
                    }
                }
                else {
                    return '';
                }
            };
        });

        //Common Filters
        app.filter('serverUrl', function ($filter) {
            return function (input) {
                if (input.startsWith("~/"))
                    return input.replace("~/", "/LP.CommissionEngine.Administration.Web.Oman/");
                return input;
            };
        });

        //Important Directives
        app.directive('isolateForm', [function () {
            return {
                restrict: 'A',
                require: '?form',
                link: function (scope, elm, attrs, ctrl) {
                    if (!ctrl) {
                        return;
                    }

                    // Do a copy of the controller
                    var ctrlCopy = {};
                    angular.copy(ctrl, ctrlCopy);

                    // Get the parent of the form
                    var parent = elm.parent().controller('form');
                    // Remove parent link to the controller
                    if (typeof parent != 'undefined') {
                        parent.$removeControl(ctrl);
                    }

                    // Replace form controller with a "isolated form"
                    var isolatedFormCtrl = {
                        $setValidity: function (validationToken, isValid, control) {
                            ctrlCopy.$setValidity(validationToken, isValid, control);
                            if (typeof parent != 'undefined')
                                parent.$setValidity(validationToken, true, ctrl);
                        },
                        $setDirty: function () {
                            elm.removeClass('ng-pristine').addClass('ng-dirty');
                            ctrl.$dirty = true;
                            ctrl.$pristine = false;
                        },
                    };
                    angular.extend(ctrl, isolatedFormCtrl);
                }
            };
        }]);
    }
})();
