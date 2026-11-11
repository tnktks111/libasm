NAME = libasm.a
SRC_DIR = src
OBJ_DIR = obj

NASM = nasm
NASMFLAGS = -f elf64

AR = ar
ARFLAGS = rcs

BASENAMES = ft_strlen ft_strcpy ft_strcmp ft_write ft_read ft_strdup ft_calloc
BONUS_BASENAMES = ft_atoi_base_bonus ft_list_push_front_bonus ft_list_size_bonus ft_list_sort_bonus ft_list_remove_if_bonus ft_simd_memchr_bonus

OBJS = $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(BASENAMES)))
BONUS_OBJS = $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(BONUS_BASENAMES)))

BUILD_OBJS = $(OBJS)

ifneq ($(filter bonus,$(MAKECMDGOALS)),)
BUILD_OBJS += $(BONUS_OBJS)
endif

ARCHIVE_MEMBERS := $(shell $(AR) t $(NAME) 2>/dev/null)

ifneq ($(sort $(ARCHIVE_MEMBERS)),$(sort $(notdir $(BUILD_OBJS))))
.PHONY: $(NAME)
endif

all: $(NAME)

bonus: $(NAME)

$(NAME): $(BUILD_OBJS)
	rm -f $@.tmp
	$(AR) $(ARFLAGS) $@.tmp $^
	mv -f $@.tmp $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) $< -o $@

clean:
	rm -rf $(OBJ_DIR)
	rm -f $(NAME).tmp

fclean: clean
	rm -f $(NAME)

re: fclean
	$(MAKE) all

.PHONY: all bonus clean fclean re