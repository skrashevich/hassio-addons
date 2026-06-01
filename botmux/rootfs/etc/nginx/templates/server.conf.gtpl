server {
    listen {{ .port }} default_server;
    listen [::]:{{ .port }} default_server;

    absolute_redirect off;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Authorization $ingress_authorization;

        proxy_redirect / $http_x_ingress_path/;

        sub_filter_once off;
        sub_filter_types application/javascript text/javascript;

        sub_filter '<head>' '<head><base href="$http_x_ingress_path/">';
        sub_filter 'href="/' 'href="$http_x_ingress_path/';
        sub_filter "fetch('/" "fetch('$http_x_ingress_path/";
        sub_filter 'fetch("/' 'fetch("$http_x_ingress_path/';
        sub_filter "await fetch('/" "await fetch('$http_x_ingress_path/";
        sub_filter "api('/" "api('$http_x_ingress_path/";
        sub_filter 'api("/' 'api("$http_x_ingress_path/';
        sub_filter "await api('/" "await api('$http_x_ingress_path/";
        sub_filter '`/api/' '`$http_x_ingress_path/api/';
        sub_filter "new EventSource('/" "new EventSource('$http_x_ingress_path/";
        sub_filter 'new EventSource("/' 'new EventSource("$http_x_ingress_path/';
        sub_filter "new EventSource(\`/" "new EventSource(\`$http_x_ingress_path/";
    }
}
