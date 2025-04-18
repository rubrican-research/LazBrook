unit config.routes;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, route.base, BrookUtility,
    route.users;
const

    AppRoutesTemplate: TLazBrookRoutes = (
        (
            entryPoint: '/';
            comment: 'This is a template to define routes.' + sLineBreak +
            'You can create different constants (or variables) for different parts '+ sLineBreak +
            'of your application instead of having it all in one place';
            authReq: false;
            endpoints : (
                (
                    regex: '/';
                    name: 'Home';
                    comment:'';
                    default:true;
                    methods:[rmGET, rmPOST];
                    routeClass: nil;
                    routeFactory: nil;
                    routeFactoryMethod: nil;
                )
            )
        )
    );

    UserRoutes: TLazBrookRoutes = (
            (
                entryPoint: '/users';
                comment:    'Users endpoint';
                authReq: false;
                endpoints : (
                    (
                        regex: '/';
                        name: 'User Home';
                        comment:'';
                        default:true;
                        methods:[rmGET];
                        routeClass: TRouteGetUserList;
                    ),

                    (
                        regex: CONCAT('/(', pcreUser,'/details)');
                        name: 'User Details';
                        comment:'';
                        default:false;
                        methods: [rmGET, rmPOST];
                        routeClass: TRouteGetUserDetails;
                    ),

                    (
                        regex: CONCAT('/(', pcreUser,'/login)');
                        name: 'User Login';
                        comment:'';
                        default:true;
                        methods:[rmPOST];
                        routeClass: TRoutePostDoLogin;
                    ),
                    (
                        regex: CONCAT('/elevate');
                        name: 'Elevate User';
                        comment:'';
                        default:true;
                        methods:[rmGET];
                        routeClass: TRouteGetUserDetails;
                    )

                )
            )
        );

implementation

end.

