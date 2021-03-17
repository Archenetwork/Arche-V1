pragma solidity ^0.6.0;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
abstract   contract ERC20Interface {
    /*
    总供给
    返回 数量
    */
    function totalSupply() virtual public view returns (uint);
    /*
    余额
    传入 token所有者地址
    返回 token数量
    */
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    /*
    补贴
    传入 token拥有者地址 消费者地址
    返回 剩余的数量
    */
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    /*
    转账
    传入 收款方地址 转账数量
    返回 是否成功
    */
    function transfer(address to, uint tokens) virtual public returns (bool success);
    /*
    批准
    传入 消费者地址 token数量
    返回 是否成功
    */
    function approve(address spender, uint tokens) virtual public returns (bool success);
    /*
    从某处转移
    传入 转账者地址 收款方地址 token数量
    返回 是否成功
    */
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    /*
    转账事件
    传入 转账者地址 收款方地址 token数量
    */
    event Transfer(address indexed from, address indexed to, uint tokens);
    /*
    批准事件
    传入 token所有者地址 消费者地址 token数量
    */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract PETH {
    /*
    获取用户信息
    传入 user地址
    返回
    */
    function GetUserInfo(address user) virtual public view returns (bool, uint256, address, uint256, uint256, uint256, uint256);
}
// ----------------------------------------------------------------------------
// 合约功能可在一次调用中获得批准并执行功能
//
// 从MiniMeToken借来的
// ----------------------------------------------------------------------------、
/*
批准并调用回退
*/
abstract  contract ApproveAndCallFallBack {
    /*
    收到批准
    传入 转帐者地址 token数量 token地址 数据
    */
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MFI_Stacking is Owned {
    /*
    堆栈事件
    传入 user地址 token数量
    */
    event EVENT_STACK(address indexed user, uint tokens);
    /*
    接收事件
    传入 user地址 token数量
    */
    event EVENT_RECEIVE(address indexed user, uint tokens);
    /*
    装箱事件
    传入 user地址 token数量
    */
    event EVENT_UNSTACK(address indexed user, uint tokens);

    struct User {
        //是否注册
        bool Registered;
        //user地址
        address User_Address;
        //邀请人地址
        address Referer_Address;
        //质押量
        uint Stacking_Amount;
        //贡献量
        uint Contribution_Amount;
        //加速质押量
        uint Accelerator_Stacking_Amount;
        //token数量
        uint Token_Amount;
        //开始质押区块号
        uint Stacking_Block_Number_Start;
        //操作质押区块号
        uint Stacking_Operation_Block_Stamp;
        //最近更新的加权叠加倒数总和128
        uint256 m_LastUpdatedSumOfWeightedStackingReciprocale128;
    }

    using SafeMath for uint;
    //用户更新程序的地址
    address public m_Updater_Address;
    //推荐人信息地址
    address public m_Referer_Info_Address;
    //质押token的地址
    address public m_Stacking_Address;
    //奖励token地址
    address public m_Token_Address;
    //加速质押token地址
    address public m_Accelerator_Address;
    //全局开始质押区块号
    uint public  m_Stacking_Block_Number_Start;
    //全局结束质押区块号
    uint public  m_Stacking_Block_Number_Stop;

    //全局质押总量
    uint public m_Token_Stacking;
    //全局用户总数
    uint public m_User_Count;
    //加速token总数
    uint256 public m_Accelerator_Total_Stacking;
    //m_2奖励阈值 1.5000000000000000000
    uint256 public m_2TimesThreshold = 1.5e18;
    //m_1奖励阈值 6.5000000000000000000
    uint256 public m_1TimesThreshold = 6.5e18;

    //區塊高度
    uint256 public m_WeightOfBlock;
    //最后更新的区块数
    uint256 public m_BlockNumOfLastUpdate = 0;
    //最后更新的质押量总和
    uint256 public m_TotalStackingOfLastUpdate = 0;
    //加权叠加倒数总和128
    uint256 public m_SumOfWeightedStackingReciprocale128 = 0;
    //m固定点
    uint256 public m_FIX_POINT = (1 * 2 ** 128);
    //指示游戏是否暂停true =暂停false =播放
    bool m_Game_Pause;
    //如果用户在一个区块范围内堆叠，则收取10％的接收令牌费用；
    uint256 m_Punishment_Span;
    /*
    仅有效载荷大小
    传入 大小
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    //不是游戏暂停
    modifier NotGamePause()
    {
        require(m_Game_Pause != true);
        _;
    }
    //仅注册
    modifier OnlyRegistered()
    {
        require(m_User_Map[msg.sender].Registered == true);
        _;
    }
    //一个地址对应一个用户
    mapping(address => User) public  m_User_Map;
    constructor() public {
        //初始全局质押总量为1
        m_Total_Stacking = 1;
        //加速token总数为1
        m_Accelerator_Total_Stacking = 1;
        // 初始游戏为未暂停状态
        m_Game_Pause = false;
        //初始用户人数为1
        m_User_Count = 1;
        //m惩罚范围为1
        m_Punishment_Span = 1;
        // m最近更新的块数为当前区块
        m_BlockNumOfLastUpdate = block.number;
        //全局开始质押区块号为当前区块号
        m_Stacking_Block_Number_Start = block.number;
        //全局结束质押区块号为0xff...
        m_Stacking_Block_Number_Stop = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        //m_1时间阈值为1
        m_TotalStackingOfLastUpdate = 1;
        //区块高度为10000
        m_WeightOfBlock = 10000;
    }
    /*
    设置token地址
    传入 质押的代币地址 奖励的代币地址
    */
    function Set_Token_Address(address stacking, address token) public onlyOwner {
        //质押的代币地址 = stacking抵押地址
        m_Stacking_Address = stacking;
        //奖励的代币地址 = token收益代币地址
        m_Token_Address = token;

    }
    /*
    设置推荐人信息
    传入 user地址
    */
    function Set_Referer_Info_Address(address addr) public onlyOwner {
        //推荐人信息 = user地址
        m_Referer_Info_Address = addr;

    }
    /*
    设置更新地址
    传入 更新地址
    */
    function Set_Updater_Address(address addr) public onlyOwner {
        //用户更新程序的地址 = 更新地址
        m_Updater_Address = addr;

    }
    /*
    设置奖励率阈值
    传入 2T奖励率 1T奖励率
    */
    function Set_Reward_Rate_Threshold(uint256 t2, uint256 t3) public onlyOwner {
        m_2TimesThreshold = t2;
        m_1TimesThreshold = t3;
    }
    /*
    设定惩罚范围
    传入 范围
    */
    function Set_Punishment_Span(uint span) public onlyOwner {
        //m惩罚范围 = 范围
        m_Punishment_Span = span;

    }

    /*
    项目暂停
    */
    function Pause() public onlyOwner {
        //m游戏暂停
        m_Game_Pause = true;
        //全局结束质押区块号 = 当前区块
        m_Stacking_Block_Number_Stop = block.number;
    }

    /*
    项目恢复
    */
    function Resume() public onlyOwner {
        // m游戏继续
        m_Game_Pause = false;
        // 全局结束质押区块号 = 0xfff...
        m_Stacking_Block_Number_Stop = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /*
    开始于
    传入 区块号
    */
    function Start_At(uint block_number) public onlyOwner {
        if (block_number == 0)
        {
            uint number = block.number;
            m_Stacking_Block_Number_Start = number;
        } else
        {
            m_Stacking_Block_Number_Start = block_number;
        }
    }

    /*
    停止于
    传入 区块号
    */
    function Stop_At(uint block_number) public onlyOwner {
        if (block_number == 0)
        {
            uint number = block.number;
            m_Stacking_Block_Number_Stop = number;
        } else
        {
            m_Stacking_Block_Number_Stop = block_number;
        }
    }

    /*
    获取user信息
    传入地址
    */
    function Get_User_Info(address user) public view returns (bool, address, address, uint, uint, uint)
    {
        return
        (
        m_User_Map[user].Registered,
        m_User_Map[user].User_Address,
        m_User_Map[user].Referer_Address,
        m_User_Map[user].Stacking_Amount,
        m_User_Map[user].Contribution_Amount,
        m_User_Map[user].Stacking_Operation_Block_Stamp
        );
    }
    /*
    获取游戏信息
    */
    function Get_Game_Info() public view returns (uint256, uint256, uint256)
    {
        return (
        m_Total_Stacking, m_User_Count, m_Punishment_Span
        );
    }
    /*
    注册
    */
    function Do_Registering() public NotGamePause returns (bool){
        // initialize user data
        Update_Global_Data();
        address Referer = GetRefererAddress(msg.sender);
        require(Referer != address(0), "REFERER ERROR");
        require(m_User_Map[msg.sender].Registered == false, "USER EXIST");
        m_User_Map[msg.sender].Registered = true;
        m_User_Map[msg.sender].User_Address = msg.sender;
        m_User_Map[msg.sender].Referer_Address = GetRefererAddress(msg.sender);
        m_User_Map[msg.sender].Stacking_Block_Number_Start = block.number;
        m_User_Map[msg.sender].m_LastUpdatedSumOfWeightedStackingReciprocale128 = m_SumOfWeightedStackingReciprocale128;
        //m_User_Count=m_User_Count+1;
        return true;
    }
    /*
    获取推荐人地址
    传入 user地址
    */
    function GetRefererAddress(address user) private returns (address)
    {
        (bool Register,uint256 PETH_Quota,address Referer,uint256 UserLevel,uint256 Losed,uint256 PickedUp,uint256 ExactProfit) = PETH(m_Referer_Info_Address).GetUserInfo(user);
        return (Referer);
    }
    /*
    质押
    传入 质押数量
    */
    function Do_Stacking(uint stacking_amount) public OnlyRegistered NotGamePause returns (bool){

        //transfer from user to contract
        bool res = false;
        res = ERC20Interface(m_Stacking_Address).transferFrom(msg.sender, address(this), stacking_amount);
        if (res == false)
        {
            //if failed revert transaction;
            revert();
        }
        uint256 old_stacking_amount = m_User_Map[msg.sender].Stacking_Amount;

        // update token value in pass;
        Update_Global_Data();
        Update_User(msg.sender, false);
        m_User_Map[msg.sender].Stacking_Operation_Block_Stamp = block.number;
        // update user and contract data
        m_Total_Stacking = m_Total_Stacking.add(stacking_amount);
        m_User_Map[msg.sender].Stacking_Amount = m_User_Map[msg.sender].Stacking_Amount + stacking_amount;

        //------------------------------------------------------------
        // add contribute
        //------------------------------------------------------------
        address referer_address = GetRefererAddress(msg.sender);
        Update_User(referer_address, false);
        m_User_Map[referer_address].Contribution_Amount = m_User_Map[referer_address].Contribution_Amount.add(stacking_amount / 5);

        //------------------------------------------------------------
        //  add contribute
        //------------------------------------------------------------
        referer_address = GetRefererAddress(referer_address);
        Update_User(referer_address, false);
        m_User_Map[referer_address].Contribution_Amount = m_User_Map[referer_address].Contribution_Amount.add(stacking_amount / 10);

        if (old_stacking_amount < 15e16 && m_User_Map[msg.sender].Stacking_Amount >= 15e16)
        {
            m_User_Count = m_User_Count + 1;
        }

        emit EVENT_STACK(msg.sender, stacking_amount);
        return true;
    }
    /*
    收获
    */
    function Do_Receiving() public OnlyRegistered NotGamePause returns (bool) {


        //TODO: UPDATE
        Update_Global_Data();
        Update_User(msg.sender, false);
        bool res = false;


        if ((block.number - m_User_Map[msg.sender].Stacking_Operation_Block_Stamp) < m_Punishment_Span)
        {
            res = ERC20Interface(m_Token_Address).transfer(msg.sender, m_User_Map[msg.sender].Token_Amount * 9 / 10);
            ERC20Interface(m_Token_Address).transfer(address(0), m_User_Map[msg.sender].Token_Amount * 1 / 10);
            if (res == false)
            {
                revert();
            }
        } else {

            res = ERC20Interface(m_Token_Address).transfer(msg.sender, m_User_Map[msg.sender].Token_Amount);

            if (res == false)
            {
                revert();
            }
        }

        //send token to user




        emit EVENT_RECEIVE(msg.sender, m_User_Map[msg.sender].Token_Amount);

        // update user  data
        m_User_Map[msg.sender].Token_Amount = 0;


        return true;
    }
    /*
    拆箱
    传入 质押量
    */
    function Do_Unstacking(uint stacking_amount) public OnlyRegistered returns (bool)  {
        //check balance
        require(m_User_Map[msg.sender].Stacking_Amount >= stacking_amount);

        Update_Global_Data();
        Update_User(msg.sender, false);
        uint256 old_stacking_amount = m_User_Map[msg.sender].Stacking_Amount;


        bool res = false;
        res = ERC20Interface(m_Stacking_Address).transfer(msg.sender, stacking_amount);
        if (res == false)
        {
            revert();
        }
        m_User_Map[msg.sender].Stacking_Amount = m_User_Map[msg.sender].Stacking_Amount.sub(stacking_amount);
        m_Total_Stacking = m_Total_Stacking.sub(stacking_amount);

        //------------------------------------------------------------
        // delete contribute
        //------------------------------------------------------------
        address referer_address = GetRefererAddress(msg.sender);
        //Update_User(referer_address,false);
        m_User_Map[referer_address].Contribution_Amount = m_User_Map[referer_address].Contribution_Amount.sub(stacking_amount / 5);

        //------------------------------------------------------------
        //  delete contribute
        //------------------------------------------------------------
        referer_address = GetRefererAddress(referer_address);
        //Update_User(referer_address,false);
        m_User_Map[referer_address].Contribution_Amount = m_User_Map[referer_address].Contribution_Amount.sub(stacking_amount / 10);


        if (old_stacking_amount >= 15e16 && m_User_Map[msg.sender].Stacking_Amount < 15e16)
        {
            m_User_Count = m_User_Count - 1;
        }


        emit EVENT_UNSTACK(msg.sender, stacking_amount);
        return true;
    }
    /*做游戏更新*/
    function Do_Game_Update() public returns (bool){
        require(msg.sender == m_Updater_Address, "DISQUALIFIED");
        Update_Global_Data();
        //Update_User(user,false);
        return true;
    }

    /*
    更新用户
    传入 user地址
    */
    function Do_Update_User(address user) public returns (bool){
        require(msg.sender == m_Updater_Address, "DISQUALIFIED");
        //Update_Global_Data();
        require(m_User_Map[user].Registered == true);
        Update_User(user, false);
        return true;
    }

    /*
    更新全局数据
    */
    function Update_Global_Data() private
    {
        uint block_num_clamp = block.number;
        if (block_num_clamp > m_Stacking_Block_Number_Stop)
        {
            block_num_clamp = m_Stacking_Block_Number_Stop;
        }
        if (block_num_clamp < m_Stacking_Block_Number_Start)
        {
            block_num_clamp = m_Stacking_Block_Number_Start;
        }

        uint256 block_span = block_num_clamp - m_BlockNumOfLastUpdate;
        if (block_span == 0)
        {
            //m_TotalStackingOfLastUpdate=stacking_amount+m_TotalStackingOfLastUpdate;
        } else {
            uint256 delta = m_FIX_POINT;
            uint256 t_total_stacking = m_Total_Stacking;
            delta = delta / t_total_stacking;
            delta = delta * block_span * m_WeightOfBlock;
            m_SumOfWeightedStackingReciprocale128 = m_SumOfWeightedStackingReciprocale128 + delta;
        }
        m_BlockNumOfLastUpdate = block_num_clamp;
    }
    /*
    做更新
    */
    function Do_Update() public OnlyRegistered NotGamePause returns (bool){
        Update_Global_Data();
        Update_User(msg.sender, false);
        return true;
    }
    /*
    更新用户
    传入 用户地址 是否惩罚
    */
    function Update_User(address user, bool punishment) private
    {
        if (m_User_Map[user].Registered == false)
        {
            return;
        }
        uint block_num_clamp = block.number;
        if (block_num_clamp > m_Stacking_Block_Number_Stop)
        {
            block_num_clamp = m_Stacking_Block_Number_Stop;
        }

        m_User_Map[user].User_Address = user;
        //// check user's block number which should be lower than  current number and greater than 0;
        if (m_User_Map[user].Stacking_Block_Number_Start <= m_Stacking_Block_Number_Start)
        {
            m_User_Map[user].Stacking_Block_Number_Start = block_num_clamp;
        }
        if (m_User_Map[user].Stacking_Block_Number_Start > block_num_clamp)
        {
            m_User_Map[user].Stacking_Block_Number_Start = block_num_clamp;
        }
        if (m_User_Map[user].Stacking_Block_Number_Start >= m_Stacking_Block_Number_Stop)
        {
            m_User_Map[user].Stacking_Block_Number_Start = m_Stacking_Block_Number_Stop;
        }
        ////Get how many blocks between last operation and current block///

        //uint block_span=block_num_clamp - m_User_Map[user].Stacking_Block_Number_Start;

        ////BASE///////////////////////////////////////////////////////////////
        uint FIXED_POINT = (2 ** 12);
        uint quantity = m_SumOfWeightedStackingReciprocale128.sub(m_User_Map[user].m_LastUpdatedSumOfWeightedStackingReciprocale128);
        quantity = quantity / fixed_point;
        quantity = (m_User_Map[user].Stacking_Amount + m_User_Map[user].Contribution_Amount) * quantity;
        quantity = quantity / (m_FIX_POINT);
        quantity = quantity * fixed_point;
        //////////////////////////////////////

        quantity = quantity * 10;
        quantity = quantity / 13;
        /////////////////////////////////////
        uint prize_rate = GetAccelerationRate(user);
        quantity = quantity * prize_rate;
        quantity = quantity / 3;
        ////Punishment/////////////////////////////////////////////////////////////////////////
        if (punishment)
        {
            uint256 burn_quantity = quantity / 10;
            //TODO：burn 
            bool res = false;
            //
            res = ERC20Interface(m_Token_Address).transfer(address(0), burn_quantity);
            quantity = TakeFee10(quantity);
        }

        ////Update Token Data////////////////////////////////////////////////////////////
        m_User_Map[user].Token_Amount = m_User_Map[user].Token_Amount.add(quantity);


        ////Update Block Number////////////////////////////////////////////////////////////
        m_User_Map[user].Stacking_Block_Number_Start = block_num_clamp;
        ////Update LastUpdatedSumOfWeightedStackingReciprocale128////////////////////////////////////////////////////////////
        m_User_Map[user].m_LastUpdatedSumOfWeightedStackingReciprocale128 = m_SumOfWeightedStackingReciprocale128;


    }
    /*
    获取加速度
    传入 用户地址
    */
    function GetAccelerationRate(address user) private view returns (uint)
    {
        //uint t_s=m_Total_Stacking;
        //uint a_s=t_s/m_User_Count;
        //uint a_s_range_left=a_s*1160/1000;
        //uint a_s_range_right=a_s*2000/1000;
        if (m_User_Map[user].Stacking_Amount < m_2TimesThreshold)
        {
            return 2;
        }
        if (m_User_Map[user].Stacking_Amount > m_1TimesThreshold)
        {
            return 1;
        }
        return 3;
    }

    /*
    取代币
    传入 代币地址 代币数量
    */
    function Take_Token(address token_address, uint token_amount) public onlyOwner {
        ERC20Interface(token_address).transfer(msg.sender, token_amount);
    }
    /*
    收取费用10
    传入 token数量
    */
    function TakeFee10(uint token_amount) private pure returns (uint) {
        uint res = token_amount;
        res = res * 9;
        res = res / 10;
        return res;
    }

    /*
    查看收货
    传入 user地址
    */
    function ViewReceiving(address user) public view returns (uint) {
        ////Get how many blocks between last operation and current block///
        uint block_num_clamp = block.number;
        if (block_num_clamp > m_Stacking_Block_Number_Stop)
        {
            block_num_clamp = m_Stacking_Block_Number_Stop;
        }
        if (block_num_clamp < m_Stacking_Block_Number_Start)
        {
            block_num_clamp = m_Stacking_Block_Number_Start;
        }

        uint256 block_span = block_num_clamp - m_BlockNumOfLastUpdate;
        uint256 t_SumOfWeightedStackingReciprocale128 = m_SumOfWeightedStackingReciprocale128;
        if (block_span == 0)
        {
            //m_TotalStackingOfLastUpdate=stacking_amount+m_TotalStackingOfLastUpdate;
        } else {
            uint256 delta = m_FIX_POINT;
            uint256 t_total_stacking = m_Total_Stacking;
            delta = delta / t_total_stacking;
            delta = delta * block_span * m_WeightOfBlock;
            t_SumOfWeightedStackingReciprocale128 = m_SumOfWeightedStackingReciprocale128 + delta;
        }
        ////BASE///////////////////////////////////////////////////////////////
        uint fixed_point = (2 ** 12);
        uint quantity = t_SumOfWeightedStackingReciprocale128.sub(m_User_Map[user].m_LastUpdatedSumOfWeightedStackingReciprocale128);
        quantity = quantity / fixed_point;
        quantity = (m_User_Map[user].Stacking_Amount + m_User_Map[user].Contribution_Amount) * quantity;
        quantity = quantity / (m_FIX_POINT);
        quantity = quantity * fixed_point;
        //////////////////////////////////////

        quantity = quantity * 10;
        quantity = quantity / 13;
        /////////////////////////////////////
        uint prize_rate = GetAccelerationRate(user);
        quantity = quantity * prize_rate;
        quantity = quantity / 3;


        /////////////////////////////////////////////////////////////////////////////


        uint res = quantity + m_User_Map[user].Token_Amount;
        return res;
    }

    /*
    设置区块高度
    传入 区块高度
    */
    function Set_Block_Weight(uint256 block_weight) public onlyOwner
    {
        m_WeightOfBlock = block_weight;
    }

}
