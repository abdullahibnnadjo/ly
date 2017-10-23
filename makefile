BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj
SRC_DIR=src
INC_DIR=include
SE_DIR=selinux

SRC= $(wildcard $(SRC_DIR)/*.c)
OBJ= $(SRC:$(SRC_DIR)%.c=$(OBJ_DIR)%.o)
BIN= $(BUILD_DIR)/ly

CFLAGS= -std=c99 -pedantic -Wall -I $(INC_DIR) -D_XOPEN_SOURCE=500
LDFLAGS= -lform -lncurses -lpam -lpam_misc -lX11 $(LDFLAGS_USR)

# Uncomment and modify to your needs
# LDFLAGS_USR= -L/usr/lib/security -l:pam_loginuid.so
# INSTALL_USR= ln -sf /usr/lib/security/pam_loginuid.so ${DESTDIR}/usr/lib/pam_loginuid.so

SE_MODULE_NAME= ly.pp
SE_MODULE=      $(BUILD_DIR)/$(SE_MODULE_NAME)
SE_SRC=         $(wildcard $(SE_DIR)/ly*)
SE_OBJ=         $(SE_SRC:$(SE_DIR)%=$(BUILD_DIR)%)

ifeq ($(DEBUG),1)
CFLAGS += -ggdb
else
CFLAGS  += -O2
endif

default: $(BIN)

all: $(SE_MODULE) $(BIN)

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

$(SE_OBJ): | $(BUILD_DIR)

$(BUILD_DIR)/ly.fc: $(SE_DIR)/ly.fc
	ln -rs $^ $@

$(BUILD_DIR)/ly.te: $(SE_DIR)/ly.te
	ln -rs $^ $@

$(SE_MODULE): $(SE_OBJ)
	make -C $(BUILD_DIR) -f /usr/share/selinux/devel/Makefile $(SE_MODULE_NAME)

install : $(BIN)
	install -dZ ${DESTDIR}/var/lib/ly
	install -DZ build/ly -t ${DESTDIR}/usr/bin
	install -DZ xsetup.sh -t ${DESTDIR}/usr/share/ly/bin
	install -DZ ly.service -t ${DESTDIR}/usr/lib/systemd/system
	$(INSTALL_USR)

.install_selinux: $(SE_MODULE)
	semodule -i $(SE_MODULE)

install_selinux: .install_selinux install

uninstall:
	rm -rf ${DESTDIR}/var/lib/ly
	rm -f  ${DESTDIR}/usr/bin/ly
	rm -rf ${DESTDIR}/usr/share/ly
	rm -f  ${DESTDIR}/usr/lib/systemd/system/ly.service

uninstall_selinux: uninstall
	semodule -r $(subst .pp,,$(SE_MODULE_NAME))

clean :
	rm -rf $(BUILD_DIR)
