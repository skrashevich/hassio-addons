# Home Assistant Supervisor adds X-Remote-User-* only for authenticated ingress.
# Trust that header only from the internal hassio network (not direct :8080 clients).
geo $ingress_trusted {
    default 0;
    127.0.0.0/8 1;
    172.30.32.0/23 1;
}

map "$ingress_trusted:$http_x_remote_user_id" $ingress_authorization {
    default "";
    "~^1:.+" "Bearer {{ .ingress_api_key }}";
}
