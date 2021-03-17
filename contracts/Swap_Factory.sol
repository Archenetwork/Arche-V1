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


 abstract contract ERC20Interface {
    function totalSupply()virtual  public  view returns (uint);
    function balanceOf(address tokenOwner)virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract ERC20_Gen_Lib{
    function Create(address p_owner, uint256 p_total ,string memory p_symbol , string memory p_name , uint8 p_decimals ) virtual public  returns(address);
}
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data)virtual public;
}

 abstract contract ERC20_Prop_Interface {
     

     
     function symbol()virtual  public  view returns (string memory);
     function name()virtual  public  view returns (string memory);
     function decimals()virtual  public  view returns (uint8);
    
}
abstract contract Trading_Charge
{
    function Amount(uint256 amount ,uint256 block_span) virtual public view  returns(uint256);
   
}
abstract contract D_Swap_Main
{
    
    function m_Address_of_System_Reward_Token()virtual  public view returns (address);

    function m_Trading_Charge_Lib()virtual  public view returns (address);

    function m_ERC20_Gen_Lib()virtual  public view returns (address);
    function Triger_Create(address swap ,address user,address swap_owner ,address token_head,address token_tail,uint256 sys_reward)virtual  public ;
    function Triger_Entanglement(address swap ,address user ,address op_token_head,address op_token_tail)virtual  public ;
    function Triger_Initialize(address swap ,address user,uint256 total_amount_head ,uint256 total_amount_tail ,uint256 limit_head ,uint256 limit_tail ,address rival_head,address rival_tail , uint256 pair_dlo ,uint256 option_dlo)virtual  public ;
    function Triger_Claim_For_Head(address swap ,address user,address referer)virtual  public ;
    function Triger_Claim_For_Tail(address swap ,address user,address referer)virtual  public ;
    function Triger_Deposit_For_Head(address swap ,address user, uint256 amount,uint256 deposited_amount)virtual  public ;
    function Triger_Deposit_For_Tail(address swap ,address user, uint256 amount,uint256 deposited_amount)virtual  public ;
    function Triger_Withdraw_Head(address swap ,address user ,uint256 status)virtual  public ;
    function Triger_Withdraw_Tail(address swap ,address user ,uint256 status)virtual  public ;
}

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

contract D_Swap_Factorys is Owned {

    function Set_DSwap_Main_Address(address addr) public onlyOwner
    {
        m_DSwap_Main_Address=addr;
    }
    address public m_DSwap_Main_Address=address(0);
    function Create(address user, address token_head,address token_tail,uint256 sys_reward) payable public  returns(address){
        address res= address(new D_Swap(m_DSwap_Main_Address , user,token_head,token_tail,sys_reward));
        return (res);
    }
   
}


contract D_Swap is Owned {
    

     using SafeMath for uint;
     uint256 public m_System_Reward_Amount;
     bool public m_Initialized=false;
     address public m_DSwap_Main_Address;
     
     
     string  public m_Version="0.0.1"; 
     address public m_Token_Head;
     address public m_Token_Tail;
     
     address public m_referer_Head;
     address public m_referer_Tail;
     
     address public m_OP_Token_Head;
     address public m_OP_Token_Tail;
     
     address public m_Rival_Head;
     address public m_Rival_Tail;
     
     uint256 public m_Amount_Head;
     uint256 public m_Amount_Tail;
     
     uint256 public m_Total_Amount_Head;
     uint256 public m_Total_Amount_Tail;
     
     uint256 public m_Pair_Limit_Head;
     uint256 public m_Pair_Limit_Tail;
     
     uint256 public m_Pair_Deadline;
     uint256 public m_Option_Deadline;
     
     uint256 public m_Pair_Offset;
     uint256 public m_Option_Offset;
     
     bool public m_Entanglement=false;
     
     bool public m_Option_Finish_Head=false;
     bool public m_Option_Finish_Tail=false;
     
    constructor(address swap_main,address swap_owner ,address token_head,address token_tail,uint256 sys_reward) public {
        owner =swap_owner;
        m_DSwap_Main_Address=swap_main;
        m_Token_Head=  token_head;
        m_Token_Tail=  token_tail;
        m_System_Reward_Amount=sys_reward;
        
        
    }
    function  StringConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length +4);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  
    function Set_Initializing_Params(uint256 total_amount_head ,uint256 total_amount_tail ,uint256 limit_head ,uint256 limit_tail ,address rival_head,address rival_tail , uint256 pair_dlo ,uint256 option_dlo)public  onlyOwner
    {
        
        require(total_amount_head>=limit_head && total_amount_tail>=limit_tail,"ILLEGALE AMOUNT");
        
        require(m_Initialized==false,"NO MAN EVER STEPS IN THE SAME RIVER TWICE");
        
        require(pair_dlo<option_dlo,"NO TIME MACHINE IN THE GARAGE");
        
        m_Initialized=true;
        
        m_Total_Amount_Head=total_amount_head;
        m_Total_Amount_Tail=total_amount_tail;
        
        m_Pair_Limit_Head= limit_head;
        m_Pair_Limit_Tail=limit_tail;
        
        m_Rival_Head= rival_head;
        m_Rival_Tail= rival_tail;
        
        m_Pair_Deadline=block.number+ pair_dlo;
        m_Option_Deadline=block.number+ option_dlo;
        
        m_Pair_Offset=pair_dlo;
        m_Option_Offset=option_dlo;
        D_Swap_Main(m_DSwap_Main_Address).Triger_Initialize( address(this) , msg.sender, total_amount_head , total_amount_tail , limit_head , limit_tail , rival_head, rival_tail ,  pair_dlo , option_dlo);
        
        
        ///(address sr_addr)= D_Swap_Factory(m_DSwap_Main_Address).m_Address_of_System_Reward_Token();
        ///bool res=false;
        ///res=ERC20Interface(sr_addr).transfer(msg.sender, address(this),m_Pair_Limit_Tail);
        ///if(res ==false)
        ///{
        ///    //if failed revert transaction;
        ///     revert();
        ///}
        
    }
    
    function Claim_For_Head(address referer)public
    {
        require(m_Initialized==true,"STEP INTO THE ETHER");
        m_referer_Head=referer;
        if(block.number> m_Option_Deadline)revert();
        if(m_Rival_Head !=address(0) && m_Rival_Head!=msg.sender) revert();
        if(m_Amount_Head>=m_Pair_Limit_Head)revert();
            bool res=false;
            res=ERC20Interface(m_Token_Head).transferFrom(msg.sender, address(this),m_Pair_Limit_Head);
            if(res ==false)
            {
                //if failed revert transaction;
                 revert();
            }
            m_Amount_Head=m_Amount_Head.add(m_Pair_Limit_Head);
            
            m_Rival_Head=msg.sender;
            
            Check_For_Entanglement();
            
        D_Swap_Main(m_DSwap_Main_Address).Triger_Claim_For_Head( address(this) , msg.sender,referer);

    }
    function Claim_For_Tail(address referer)public
    {
        require(m_Initialized==true,"STEP INTO THE ETHER");
        m_referer_Tail=referer;
        if(block.number> m_Option_Deadline)revert();
        if(m_Rival_Tail !=address(0) && m_Rival_Tail!=msg.sender) revert();
        if(m_Amount_Tail>=m_Pair_Limit_Tail)revert();
            bool res=false;
            res=ERC20Interface(m_Token_Tail).transferFrom(msg.sender, address(this),m_Pair_Limit_Tail);
            if(res ==false)
            {
                //if failed revert transaction;
                 revert();
            }
             m_Amount_Tail=m_Amount_Tail.add(m_Pair_Limit_Tail);
             
             
            m_Rival_Tail=msg.sender;
            
            Check_For_Entanglement();
            
        D_Swap_Main(m_DSwap_Main_Address).Triger_Claim_For_Tail( address(this) , msg.sender,referer);
    }
    function Deposit_For_Head(uint256 amount)public
    {
        if(block.number> m_Option_Deadline)revert();
        if( m_Rival_Head!=msg.sender) revert();
        if(m_Amount_Head>=m_Total_Amount_Head)revert();
        uint256 e_amount= m_Total_Amount_Head-m_Amount_Head;
        if(e_amount>amount)
        {
            e_amount=amount;
        }
        bool res=false;
        res=ERC20Interface(m_Token_Head).transferFrom(msg.sender, address(this),e_amount);
        if(res ==false)
        {
            //if failed revert transaction;
             revert();
        }
        m_Amount_Head=m_Amount_Head+e_amount;
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Deposit_For_Head( address(this) , msg.sender, amount, m_Amount_Head);

    }
    function Deposit_For_Tail(uint256 amount)public
    {
        if(block.number> m_Option_Deadline)revert();
        if( m_Rival_Tail!=msg.sender) revert();
        if(m_Amount_Tail>=m_Total_Amount_Tail)revert();
        uint256 e_amount= m_Total_Amount_Tail-m_Amount_Tail;
        if(e_amount>amount)
        {
            e_amount=amount;
        }
        bool res=false;
        res=ERC20Interface(m_Token_Tail).transferFrom(msg.sender, address(this),e_amount);
        if(res ==false)
        {
            //if failed revert transaction;
             revert();
        }
        m_Amount_Tail=m_Amount_Tail+e_amount;
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Deposit_For_Tail( address(this) , msg.sender, amount,m_Amount_Tail);
    }

    function Check_For_Entanglement()private
    {
        address m_ERC20_Gen_Lib= D_Swap_Main(m_DSwap_Main_Address).m_ERC20_Gen_Lib();
        if(m_Amount_Head>=m_Pair_Limit_Head && m_Amount_Tail>=m_Pair_Limit_Tail && block.number<= m_Pair_Deadline)
        {
             
             
            m_Entanglement=true;
            m_OP_Token_Head= (ERC20_Gen_Lib)( m_ERC20_Gen_Lib).Create (
                address(this),
                m_Total_Amount_Tail,
                StringConcat( ERC20_Prop_Interface( m_Token_Head).name() ,"_OP"),
                StringConcat(ERC20_Prop_Interface(m_Token_Head).symbol(),"_OP"),
                ERC20_Prop_Interface(m_Token_Head).decimals()
                
                );
                
            (ERC20Interface)(m_OP_Token_Head).transfer(m_Rival_Head,m_Total_Amount_Tail);
                
            m_OP_Token_Tail= (ERC20_Gen_Lib)( m_ERC20_Gen_Lib).Create (
                address(this),
                m_Total_Amount_Head,
                StringConcat(ERC20_Prop_Interface(m_Token_Tail).name(),"_OP"),
                StringConcat(ERC20_Prop_Interface(m_Token_Tail).symbol(),"_OP"),
                ERC20_Prop_Interface(m_Token_Tail).decimals()
            );
            
            (ERC20Interface)(m_OP_Token_Tail).transfer(m_Rival_Tail,m_Total_Amount_Head);
            
            
        (address sr_addr)= D_Swap_Main(m_DSwap_Main_Address).m_Address_of_System_Reward_Token();
        bool res=false;
        if(m_System_Reward_Amount>0)
        {
            
        res=ERC20Interface(sr_addr).transfer(m_referer_Head,m_System_Reward_Amount/3-2);
        res=ERC20Interface(sr_addr).transfer(m_referer_Tail,m_System_Reward_Amount/3-2);
        }
            
            
             D_Swap_Main(m_DSwap_Main_Address).Triger_Entanglement( address(this) , msg.sender,m_OP_Token_Head,m_OP_Token_Tail);
         }
    }

    function Charging_Transfer_ERC20 (address token ,address to ,uint256 amount)private
    {
        (address tc_addr)= D_Swap_Main(m_DSwap_Main_Address).m_Trading_Charge_Lib();
        uint256 exactly_amount=Trading_Charge(tc_addr).Amount(amount,m_Option_Offset);
        bool res=ERC20Interface(token).transfer(to,exactly_amount);
        ERC20Interface(token).transfer(m_DSwap_Main_Address,amount.sub(exactly_amount));
        if(res ==false)
        {
             revert();
        }
        
    }
    function Withdraw_Head()public
    {
       
        
        
        uint256 status=0;
        require(m_Option_Finish_Head==false,"Option Closed");
        m_Option_Finish_Head=true;
        //bool res;
        if(block.number> m_Pair_Deadline && m_Entanglement==false)
        {
         
         
            Charging_Transfer_ERC20(m_Token_Head,m_Rival_Head,m_Amount_Head);
            status=1;
        }
        if(block.number> m_Option_Deadline && m_Entanglement==true)
        {
            if(m_Total_Amount_Head <= m_Amount_Head && m_Total_Amount_Tail<= m_Amount_Tail)
            {
               Charging_Transfer_ERC20(m_Token_Tail,m_Rival_Head,m_Total_Amount_Tail);
               
              
                status=2;
                
            }if(m_Total_Amount_Head <= m_Amount_Head && m_Total_Amount_Tail> m_Amount_Tail)
            {
                Charging_Transfer_ERC20(m_Token_Tail,m_Rival_Head,m_Pair_Limit_Tail);
              
                Charging_Transfer_ERC20(m_Token_Head,m_Rival_Head,m_Amount_Head);
               
                
                status=3;
            }
            if( m_Total_Amount_Head> m_Amount_Head && m_Total_Amount_Tail> m_Amount_Tail)
            {
                
                Charging_Transfer_ERC20(m_Token_Head,m_Rival_Head,m_Amount_Head.sub(m_Pair_Limit_Head));
                Charging_Transfer_ERC20(m_Token_Head,m_DSwap_Main_Address,m_Pair_Limit_Head);
               
                status=4;
            }
            if( m_Total_Amount_Head> m_Amount_Head && m_Total_Amount_Tail<= m_Amount_Tail)
            {
                
                Charging_Transfer_ERC20(m_Token_Head,m_Rival_Head,m_Amount_Tail.sub(m_Pair_Limit_Head));
                //Charging_Transfer_ERC20(m_Token_Head,m_DSwap_Main_Address,m_Pair_Limit_Head);
               
                status=5;
            }
        }
        D_Swap_Main(m_DSwap_Main_Address).Triger_Withdraw_Head( address(this) , msg.sender,status);

    }
    function Withdraw_Tail()public
    {
        uint256 status=0;
        require(m_Option_Finish_Tail==false,"Option Closed");
        m_Option_Finish_Tail=true;
        //bool res;
         if(block.number> m_Pair_Deadline && m_Entanglement==false)
        {
               Charging_Transfer_ERC20(m_Token_Tail,m_Rival_Tail,m_Amount_Tail);
               
               
         
                status=1;
        }
        if(block.number> m_Option_Deadline && m_Entanglement==true)
        {
            if(m_Total_Amount_Head <= m_Amount_Head && m_Total_Amount_Tail<= m_Amount_Tail)
            {
                 Charging_Transfer_ERC20(m_Token_Head,m_Rival_Tail,m_Total_Amount_Head);
               
              
                status=2;
            }
            if(m_Total_Amount_Head > m_Amount_Head && m_Total_Amount_Tail<= m_Amount_Tail)
            {
                 Charging_Transfer_ERC20(m_Token_Head,m_Rival_Tail,m_Pair_Limit_Head);
               
                Charging_Transfer_ERC20(m_Token_Tail,m_Rival_Tail,m_Amount_Tail);
            
                status=3;
            }
            if( m_Total_Amount_Tail> m_Amount_Tail && m_Total_Amount_Head > m_Amount_Head )
            {
                
                Charging_Transfer_ERC20(m_Token_Tail,m_Rival_Tail,m_Amount_Tail.sub(m_Pair_Limit_Tail));
               
                Charging_Transfer_ERC20(m_Token_Tail,m_DSwap_Main_Address,m_Pair_Limit_Tail);
                status=4;
            }
            if( m_Total_Amount_Tail> m_Amount_Tail && m_Total_Amount_Head <= m_Amount_Head )
            {
                
                Charging_Transfer_ERC20(m_Token_Tail,m_Rival_Tail,m_Amount_Tail.sub(m_Pair_Limit_Tail));
                //Charging_Transfer_ERC20(m_Token_Tail,m_DSwap_Main_Address,m_Pair_Limit_Tail);
                status=5;
            }
        }
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Withdraw_Tail( address(this) , msg.sender, status);
    }
    
    fallback() external payable {}
    receive() external payable { 
    //revert();
    }
    function Call_Function(address addr,uint256 value ,bytes memory data) public  onlyOwner  {
    addr.call{value:value}(data);
     
    }
}
