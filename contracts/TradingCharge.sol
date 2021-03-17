contract Trading_Charges
{
    function Amount(uint256 amount ,uint256 block_span)public view returns(uint256)
    {
      uint256 charge=amount/1000;
      charge=charge*3;
      uint256 res=amount-charge;
      return res;
    }
}