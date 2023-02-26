'use strict';

import { environment } from '../../environments/environment';

angular.module('ownerList')
    .controller('OwnerListController', ['$http', function ($http) {
        var self = this;

        $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/customer/owners').then(function (resp) {
            self.owners = resp.data;
        });
    }]);
