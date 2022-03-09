//
//  File.swift
//  
//
//  Created by San Engineer on 14/08/21.
//

import Vapor
import Fluent

final class UserAuthMiddleware: Middleware {
  
    let authUrl: String = Environment.get("SERVER_URL")!

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let token = request.headers.bearerAuthorization else {
            return request.eventLoop.future(error: Abort(.unauthorized))
        }
        
        //debug
        print("\n","HEADER_TOKEN: ", token)
        // print("\n", "TEST", test)
        // print("\n","PARAMS_ID: ",id_params, "\n")
        
        return request
            .client
            .post("(\(authUrl)/user/auth/authenticate", beforeSend: {
                authRequest in 
                try authRequest.content.encode(AuthenticateData(token:token.token), as: .json)
            })
        
            .flatMapThrowing { response in
                guard let auth = try response.content.decode(Auth.self).role_id, auth == 1 else {
                    throw Abort(.unauthorized)
                }
                    
               //debug
            //    print("\n","RESPONSE:\n", response,"\n")
            //    print("\n", "TRYYY\n", try response.content.decode(Auth.self), "\n")
            //    print("\n","USER:", auth,"\n")
            //    print("\n","QUERY_DB:", data.self,"\n")
            
            }
        
            .flatMap {
                return next.respond(to: request)
            }
    }
    
}
