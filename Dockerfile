FROM swift:5.8.0 as builder

# set up the workspace
RUN mkdir /workspace
WORKDIR /workspace

# copy the source to the docker image
COPY . /workspace

RUN swift build -c release

#------- package -------
FROM swift:5.8.0-slim
# copy executable
COPY --from=builder /workspace/.build/release/ProjectQ-NotificationBot /

# set the entry point (application name)
CMD ["ProjectQ-NotificationBot"]