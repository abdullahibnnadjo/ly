BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj
SRC_DIR=src
INC_DIR=include

SRC= $(wildcard $(SRC_DIR)/*.c)
OBJ= $(SRC:$(SRC_DIR)%.c=$(OBJ_DIR)%.o)
BIN= $(BUILD_DIR)/ly

CFLAGS= -std=c99 -pedantic -Wall -I $(INC_DIR)
LDFLAGS= -L/usr/lib/security -lform -lncurses -lpam -lpam_misc -lX11 -l:pam_loginuid.so

all: $(BIN)

$(BIN): $(OBJ) | $(BUILD_DIR)
	cc $(CFLAGS) $(LDFLAGS) $(OBJ) -o $(BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(OBJ): | $(OBJ_DIR)

$(OBJ_DIR)%.o: $(SRC_DIR)%.c $(DEPS)
	cc $(CFLAGS) -MMD -c $< -o $@

-include $(OBJ_DIR)/*.d

install : $(BIN)
	install -d ${DESTDIR}/etc/ly
	install -D build/ly -t ${DESTDIR}/usr/bin
	install -D xsetup.sh -t ${DESTDIR}/etc/ly
	install -D ly.service -t ${DESTDIR}/usr/lib/systemd/system
	ln -sf /usr/lib/security/pam_loginuid.so ${DESTDIR}/usr/lib/pam_loginuid.so

clean :
	rm -rf $(BUILD_DIR)
