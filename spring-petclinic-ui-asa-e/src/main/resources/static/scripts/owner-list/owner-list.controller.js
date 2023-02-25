'use strict';

angular.module('ownerList')
    .controller('OwnerListController', ['$http', function ($http) {
        var self = this;

        $http.get($SPRING_CLOUD_GATEWAY_URL+'/api/customer/owners').then(function (resp) {
            self.owners = resp.data;
        });
    }]);
