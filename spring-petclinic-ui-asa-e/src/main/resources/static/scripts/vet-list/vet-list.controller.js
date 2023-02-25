'use strict';

angular.module('vetList')
    .controller('VetListController', ['$http', function ($http) {
        var self = this;

        $http.get($SPRING_CLOUD_GATEWAY_URL+'/api/vet/vets').then(function (resp) {
            self.vetList = resp.data;
        });
    }]);
