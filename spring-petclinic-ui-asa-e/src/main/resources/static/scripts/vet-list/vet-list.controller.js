'use strict';

import { environment } from '../../environments/environment';

angular.module('vetList')
    .controller('VetListController', ['$http', function ($http) {
        var self = this;

        $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/vet/vets').then(function (resp) {
            self.vetList = resp.data;
        });
    }]);
