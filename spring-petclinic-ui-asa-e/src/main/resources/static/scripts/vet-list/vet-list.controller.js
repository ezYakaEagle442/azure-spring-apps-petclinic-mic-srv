'use strict';

// import { environment } from '../../environments/environment';

angular.module('vetList')
    .controller('VetListController', ['$http', 'environment', function ($http, environment) {
        var self = this;

        $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/vet/vets').then(function (resp) {
            self.vetList = resp.data;
        });
    }]);
