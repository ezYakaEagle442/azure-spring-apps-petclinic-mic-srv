'use strict';

// import { environment } from '../../environments/environment';

angular.module('petForm')
    .controller('PetFormController', ['$http', '$state', '$stateParams', 'environment', function ($http, $state, $stateParams, environment) {
        var self = this;
        var ownerId = $stateParams.ownerId || 0;

        $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/customer/petTypes').then(function (resp) {
            self.types = resp.data;
        }).then(function () {

            var petId = $stateParams.petId || 0;

            if (petId) { // edit
                $http.get(environment.SPRING_CLOUD_GATEWAY_URL+"/api/customer/owners/" + ownerId + "/pets/" + petId).then(function (resp) {
                    self.pet = resp.data;
                    self.pet.birthDate = new Date(self.pet.birthDate);
                    self.petTypeId = "" + self.pet.type.id;
                });
            } else {
                $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/customer/owners/' + ownerId).then(function (resp) {
                    self.pet = {
                        owner: resp.data.firstName + " " + resp.data.lastName
                    };
                    self.petTypeId = "1";
                })

            }
        });

        self.submit = function () {
            var id = self.pet.id || 0;

            var data = {
                id: id,
                name: self.pet.name,
                birthDate: self.pet.birthDate,
                typeId: self.petTypeId
            };

            var req;
            if (id) {
                req = $http.put(environment.SPRING_CLOUD_GATEWAY_URL+"/api/customer/owners/" + ownerId + "/pets/" + id, data);
            } else {
                req = $http.post(environment.SPRING_CLOUD_GATEWAY_URL+"/api/customer/owners/" + ownerId + "/pets", data);
            }

            req.then(function () {
                $state.go("owners", {ownerId: ownerId});
            }, function (response) {
                var error = response.data;
                error.errors = error.errors || [];
                alert(error.error + "\r\n" + error.errors.map(function (e) {
                        return e.field + ": " + e.defaultMessage;
                    }).join("\r\n"));
            });
        };
    }]);
