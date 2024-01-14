#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <errno.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main(int argc, char **argv)
{
    struct addrinfo *res;
    char toresolve[] = "jeanpierre.moe";
    struct addrinfo *curr;

    if (argc > 1) {
        strcpy(toresolve, argv[1]);
    }

    struct addrinfo hints = {
        .ai_family = AF_INET,
        .ai_flags = AI_CANONNAME,
        .ai_socktype = 0,
        .ai_protocol = 0,
        .ai_canonname = NULL,
        .ai_addr = NULL,
        .ai_next = NULL
    };

    int fres = getaddrinfo(toresolve, NULL, &hints, &res);

    if (fres != 0) {
        puts("ERROR with getaddrinfo");
        if (fres == EAI_SYSTEM) {
            printf("%s\n", strerror(errno));
        }

        if (fres == EAI_BADFLAGS) {
            puts("wrong flags");
        }

        if (fres == EAI_NONAME) {
            puts("name or service not known");
        }

        if (fres == EAI_ADDRFAMILY) {
            puts("ADDRFAMILY");
        }
        return -1;
    }

    if (res == NULL){
        puts("res is null");
    }

    for (curr = res; curr != NULL; curr = curr->ai_next) {

        printf("%s\t%s\n", toresolve, inet_ntoa(((struct sockaddr_in*)curr->ai_addr)->sin_addr));
    }

    return 0;
}