package org.petify.backend.controllers;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import org.petify.backend.utils.RSAKeyProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class JwkSetEndpoint {

    @Autowired
    private RSAKeyProperties keys;

    @GetMapping("/.well-known/jwks.json")
    public Map<String, Object> getJwks() {
        RSAKey key = new RSAKey.Builder(keys.getPublicKey())
                .keyID("auth-key")
                .build();
        return new JWKSet(key).toJSONObject();
    }
}