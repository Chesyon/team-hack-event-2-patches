#include <pmdsky.h>
#include <cot.h>

uint8_t CUSTOM_MENU_ID = 0xFF;
uint8_t ITEM_IDXS[50];

extern void GetItemNameAdvanced(char* buffer, struct item* item, undefined4 what, int the, int heck);
extern void item_Set(int idx, struct bulk_item* item);

char* ItemSetEntryFn(char* buffer, int option_id)
{
  GetItemNameAdvanced(buffer, GetItemAtIdx(ITEM_IDXS[option_id]), 0x2322b8c, 1, 1);
  return buffer;
}

void CreateItemSetMenu() {
  struct window_params menu_params = { .x_offset = 2, .y_offset = 2, .box_type = {0xFF} };
  struct window_flags menu_flags = { .a_accept = true, .b_cancel = true, .se_on = true, .menu_title = true, .menu_lower_bar = true, .no_accept_button = true};
  struct window_extra_info menu_info = {.title_string_id = 815, .title_height = 0x10 };
  int menu_options = 0; int menu_options_pp = 0; int capacity = GetCurrentBagCapacity();
  for(int i = 0; i < capacity; i++)
  {
    struct item* item = &BAG_ITEMS_PTR[i];
    if(item->f_exists)
    {
      ITEM_IDXS[menu_options] = i;
      menu_options++;
    }
  }
  menu_options_pp = menu_options < 8 ? menu_options : 8;
  if(menu_options > 0)
    CUSTOM_MENU_ID = CreateAdvancedMenu(&menu_params, menu_flags, &menu_info, &ItemSetEntryFn, menu_options, menu_options_pp);
}

void __attribute__((used)) NewMenuStart(int menu_id) {
  CUSTOM_MENU_ID = 0xFF;
  switch(menu_id) {
    case 80:
      CreateItemSetMenu();
      break;
  }
}

int __attribute__((used)) NewMenuEnd(int menu_id) {
  int return_val = 0;
  int menu_result = 0;
  if(CUSTOM_MENU_ID == 0xFF)
    return 0xFF;
  switch(menu_id) {
    case 80:
      if(!IsAdvancedMenuActive(CUSTOM_MENU_ID)) {
        menu_result = GetAdvancedMenuResult(CUSTOM_MENU_ID);
        CloseAdvancedMenu(CUSTOM_MENU_ID);
        if(menu_result >= 0) {
          struct item* item = GetItemAtIdx(ITEM_IDXS[menu_result]);
          struct bulk_item item_set_item = {item->id, item->quantity};
          item_Set(0, &item_set_item);
          RemoveItemNoHole(ITEM_IDXS[menu_result]);
          return_val = 1;
        }
        else
          return_val = 2;
      }
      break;
  }
  return return_val;
}

void __attribute__((naked)) MenuStartHook()
{
  asm("mov r0,r5");
  asm("bl NewMenuStart");
  asm("b MenuStartFinish");
}

void __attribute__((naked)) MenuEndHook()
{
  asm("bl NewMenuEnd");
  asm("str r0,[r6]");
  asm("b MenuEndFinish");
}
