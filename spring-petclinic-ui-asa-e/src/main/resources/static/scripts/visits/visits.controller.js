'use strict';

// import { environment } from '../../environments/environment';

angular.module('visits')
    .controller('VisitsController', ['$http', '$state', '$stateParams', '$filter', 'environment', function ($http, $state, $stateParams, $filter, environment) {
        var self = this;
        var petId = $stateParams.petId || 0;
        var url = environment.SPRING_CLOUD_GATEWAY_URL+"/api/visit/owners/" + ($stateParams.ownerId || 0) + "/pets/" + petId + "/visits";
        self.date = new Date();
        self.desc = "";

        $http.get(url).then(function (resp) {
            self.visits = resp.data;
        });

        self.submit = function () {
            var data = {
                date: $filter('date')(self.date, "yyyy-MM-dd"),
                description: self.desc
            };

            $http.post(url, data).then(function () {
                $state.go("owners", { ownerId: $stateParams.ownerId });
            }, function (response) {
                var error = response.data;
                alert(error.error + "\r\n" + error.errors.map(function (e) {
                        return e.field + ": " + e.defaultMessage;
                    }).join("\r\n"));
            });
        };
    }]);
