NAME = libasm.a
SRC_DIR = src
OBJ_DIR = obj

NASM = nasm
NASMFLAGS = -f elf64

AR = ar
ARFLAGS = rcs

BASENAMES = ft_strlen ft_strcpy ft_strcmp ft_write ft_read ft_strdup ft_calloc

SRCS = $(addprefix $(SRC_DIR)/, $(addsuffix .s, $(BASENAMES)))
OBJS = $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(BASENAMES)))

all: $(NAME)

$(NAME): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) $< -o $@

clean:
	rm -rf $(OBJ_DIR)

fclean: clean
	rm -f $(NAME)

re: fclean
	$(MAKE) all

.PHONY: all clean fclean re
