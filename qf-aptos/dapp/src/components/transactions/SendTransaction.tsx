import React, { useEffect, useState } from 'react';

import '../../styles.scss';
import { MaybeHexString, AptosClient } from 'aptos';
import { TAptosCreateTx } from '../../types';
import { aptosQFAddress } from '../../consts';

interface ISendTransaction {
  onSendTransaction: (tx: TAptosCreateTx) => Promise<any>;
  sender?: MaybeHexString | null;
}

const ResourceType = aptosQFAddress + '::qf::Data'

export const SendTransaction = ({ onSendTransaction, sender }: ISendTransaction) => {
  const [client] = useState<AptosClient>(new AptosClient('https://fullnode.devnet.aptoslabs.com'));

  const [qfData, setQfData] = useState<string>('');

  const handleButton = () => {
    client.getAccountResource(aptosQFAddress, ResourceType)
    .then((data) => {
      setQfData(JSON.stringify(data.data as any, null, 2));
    });
  };


  return (
    <div className="send-transaction">
      <div> QF DATA: </div>
      <div className="divider"/>
      <pre className='code'>
        {qfData}
      </pre>
      <div className="divider"/>
      <button className="w-button send-transaction__button" onClick={handleButton}>Refresh</button>
    </div>
  );
};
