async function main() {

  const [deployer] = await ethers.getSigners();

  console.log("当前合约部署者:",deployer.address);
  
  console.log("合约部署者余额:", (await deployer.getBalance()).toString());
  
  //-------------------------------------------------
  const D_Swap_Mains = await ethers.getContractFactory("D_Swap_Mains");
  
  const d_Swap_Mains = await D_Swap_Mains.deploy();
  
  console.log("D_Swap_Mains address:", d_Swap_Mains.address);
  
  
  //-------------------------------------------------d_Swap_Mains.address,deployer.address,"0x8F622CB4006Cf8ade9486656BDda0E6c4CD50486","0xD1EB7771E2aFe7AF7b535270c0Ed501C2cDCcAe5",100
  
  const D_Swap_Factorys = await ethers.getContractFactory("D_Swap_Factorys");
  
  const d_Swap_Factorys= await D_Swap_Factorys.deploy();

  console.log("d_Swap_Factorys address:", d_Swap_Factorys.address);
 
  //-------------------------------------------------
  
  const OP_ERC20 = await ethers.getContractFactory("OP_ERC20");
  
  const oP_ERC20 = await OP_ERC20.deploy(deployer.address,10000,"gg","GGB",18);

  console.log("oP_ERC20 address:", oP_ERC20.address);
  
  //-------------------------------------------------
  
  const Trading_Charge = await ethers.getContractFactory("Trading_Charges");
  
  const frading_Charge = await Trading_Charge.deploy();

  console.log("frading_Charge address:", frading_Charge.address);
  
  
  await d_Swap_Mains.Set_ERC20_Gen_Lib(oP_ERC20.address);
  console.log("D_Swap_Mains.Set_ERC20_Gen_Lib--:", oP_ERC20.address); 
  
  await d_Swap_Mains.Set_Trading_Charge_Lib(frading_Charge.address);
  console.log("D_Swap_Mains.Set_Trading_Charge_Lib--:", frading_Charge.address); 
  
  await d_Swap_Mains.Set_System_Reward_Address("0x8F622CB4006Cf8ade9486656BDda0E6c4CD50486");
  console.log("D_Swap_Mains.Set_System_Reward_Address--:", "0x8F622CB4006Cf8ade9486656BDda0E6c4CD50486"); 
  
  await d_Swap_Mains.Set_Factory_Lib(d_Swap_Factorys.address);
  console.log("D_Swap_Mains.Set_Factory_Lib--:", d_Swap_Factorys.address); 
  
  await d_Swap_Factorys.Set_DSwap_Main_Address(d_Swap_Mains.address);
  console.log("d_Swap_Factorys.Set_DSwap_Main_Address--:", d_Swap_Mains.address); 
  
  
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
