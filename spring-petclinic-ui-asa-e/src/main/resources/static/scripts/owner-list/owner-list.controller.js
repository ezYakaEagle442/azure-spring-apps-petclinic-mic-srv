'use strict';

// import { environment } from '../../environments/environment';

angular.module('ownerList')
    .controller('OwnerListController', ['$http','environment', function ($http, environment) {
        var self = this;

        $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/customer/owners').then(function (resp) {
            self.owners = resp.data;
        });
    }]);
