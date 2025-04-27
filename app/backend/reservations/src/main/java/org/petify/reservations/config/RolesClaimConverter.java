package org.petify.reservations.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.*;
import java.util.stream.Collectors;

public class RolesClaimConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {

        Object claim = jwt.getClaim("roles");
        if (claim == null) {
            return Collections.emptySet();
        }

        Collection<String> rawRoles;

        if (claim instanceof String str) {
            rawRoles = Arrays.asList(str.trim().split("\\s+"));
        } else if (claim instanceof Collection<?> col) {
            rawRoles = col.stream().map(Object::toString).collect(Collectors.toSet());
        } else {
            return Collections.emptySet();
        }

        return rawRoles.stream()
                .filter(r -> !r.isBlank())
                .map(r -> r.startsWith("ROLE_") ? r : "ROLE_" + r)
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toSet());
    }
}
