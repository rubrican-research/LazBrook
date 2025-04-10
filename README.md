# LazBrook
 Web App template for FPC/Lazarus using Brook Framework [work in progress]. 
 
## Purpose
Building complex webserver applications has become relatively easier with frameworks and libraries for backend development. Although JS frameworks are now the most popular and the tooling has become very mature, the challenge of maintaining and growing  webserver applications can only be avoided when every developer strictly adhere to the standards of their chosen dev-stack.

This library is built on [Silvio's](https://github.com/silvioprog),[BrookFramework](https://github.com/risoflora/brookframework). The intention is
1. **One codebase, cross-platform binaries + as gui, console or lib**. This library gives you a starting point to create your application but with the flexibility to compile as:
    1. GUI application with inbuilt webserver
    2. Console application (by simply defining compiler flags)
    3. Library (dll, so, dylib) - where you can compile the existing code as a library, which can be loaded dynamically by a container application. The library implements a way to identify it as a LazBrook webserver and it can announce all the endpoints that it currently handles. This makes it easier to build and maintain microservices.
2. **Route and handler declaration**: To allow a self-explanatory definition of routes and route-handlers
3. **Built-in file server** with caching (implemented with ETAG).
4. Framework for **user authentication and authorisation**
5. **Request sentry**: that checks each incoming request:
   1. does the requested url **_require authentication_**? If yes, redirect to login page
   2. is the user **_session still valid_**? if not, redirect to login page
   3. is the _**user authorized**_ to make the request? if not, reply with an error.
   4. manage additional security methods.
      
## Route definition
You can define routes like this
```Pascal
const
    pcreUser = '(?P<user>[\w\-\._@\s]+)'; // creates a named group called "user"
    UserRoutes: TLazBrookRoutes = (
            (
                entryPoint: '/users';
                comment:    'Users endpoint';
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
```
Notice that you can assign a TRoutexxx class to the endpoints which will handle the incoming request. This makes it easy to know how each server endpoint is defined. Additionally, you can also assign a factory method to the endpoint defintion where you can implement complex initialization of the TRoutexxx handler class. 

The **comment** field is specifically there to add documention for the endpoint. The library supports generation of list of all endpoints supported by the server, where the comment field can serve as a good source of information about the capabilities of the server.

## How to use
1. Open and compile the lazbrook package in Lazarus. Then you can include this package with any application you are building.
2. Copy the appropriate files from the folder "/deploy" to your binary output folder.
3. Define your routes as constants, while also creating TRoutexxx classes that will implement your logic (You can use any naming convention for your classes. They just need to be derived from TBrookURLRouteClass)

## For console applications
1. Set your LCLWidgetType to nogui in your project's Compiler Options. ![image](https://github.com/user-attachments/assets/eca7df36-7f10-44c4-b152-2621b907b145)
2. Recommend the use of complier defines to control the code that gets compiled. Note that console applications may not always use an Application.Run. You would have to implement your own main loop with readln or fppause.


 
   
 
