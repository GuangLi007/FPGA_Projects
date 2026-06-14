#include <stdio.h>
#include "xil_printf.h"
#include "xgpiops.h"
#include "xgpiops_hw.h"

#define EMIOLED1 54   // PL_LED1
#define EMIOKEY1 55   // PL_KEY1

#define input  0
#define output 1

XGpioPs Gpios;

int main()
{
    int Status;
    XGpioPs_Config *ConfigPtr;

    // 初始化GPIO
    printf("EMIO Test! \n\r");
    
    // 修正1：XPAR_XGPIOPS_0_DEVICE_ID（注意是GPIOPS不是GPI0PS）
    ConfigPtr = XGpioPs_LookupConfig(0);
    Status = XGpioPs_CfgInitialize(&Gpios, ConfigPtr, ConfigPtr->BaseAddr);
    if (Status != XST_SUCCESS){
        return XST_FAILURE;
    }

    // 设置LED接口方向为输出
    XGpioPs_SetDirectionPin(&Gpios, EMIOLED1, output);
    // 设置KEY接口方向为输入
    XGpioPs_SetDirectionPin(&Gpios, EMIOKEY1, input);   // 修正2：EMIOKEY1
    // 使能LED接口输出
    XGpioPs_SetOutputEnablePin(&Gpios, EMIOLED1, 1);

    while(1)
    {
        // 读取KEY状态，改变LED输出电平
        if(XGpioPs_ReadPin(&Gpios, EMIOKEY1))           // 修正3：EMIOKEY1
        {
            XGpioPs_WritePin(&Gpios, EMIOLED1, 1);
        }
        else
        {
            XGpioPs_WritePin(&Gpios, EMIOLED1, 0);
        }
    }

    return XST_SUCCESS;
}