'use strict';

// import { environment } from '../../environments/environment';

angular.module('ownerForm')
    .controller('OwnerFormController', ["$http", '$state', '$stateParams', 'environment', function ($http, $state, $stateParams, environment) {
        var self = this;

        var ownerId = $stateParams.ownerId || 0;

        if (!ownerId) {
            self.owner = {};
        } else {
            $http.get(environment.SPRING_CLOUD_GATEWAY_URL+"/api/customer/owners/" + ownerId).then(function (resp) {
                self.owner = resp.data;
            });
        }

        self.submitOwnerForm = function () {
            var id = self.owner.id;
            var req;
            if (id) {
                req = $http.put(environment.SPRING_CLOUD_GATEWAY_URL+"/api/customer/owners/" + id, self.owner);
            } else {
                req = $http.post(environment.SPRING_CLOUD_GATEWAY_URL+"/api/customer/owners", self.owner);
            }

            req.then(function () {
                $state.go('owners');
            }, function (response) {
                var error = response.data;
                alert(error.error + "\r\n" + error.errors.map(function (e) {
                        return e.field + ": " + e.defaultMessage;
                    }).join("\r\n"));
            });
        };
    }]);
