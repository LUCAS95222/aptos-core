import React, { useState } from 'react';

import '../../styles.scss';
import { MaybeHexString } from 'aptos';
import { TAptosCreateTx } from '../../types';
import { aptosQFAddress } from '../../consts';

interface ISendTransaction {
  onSendTransaction: (tx: TAptosCreateTx) => Promise<any>;
  sender?: MaybeHexString | null;
}

export const AddTrack = ({ onSendTransaction, sender }: ISendTransaction) => {
  const [transactionHash, setTransactionHash] = useState(null);
  const senderAddress = sender ? sender.toString() : '';

  const initialValue = {
    sender: senderAddress,
    gasUnitPrice: '100',
    maxGasAmount: '10000',
    expiration: new Date().getTime().toString(),
    payload: {
      arguments: ['3'],
      function: aptosQFAddress + '::qf::add_track',
      type: 'entry_function_payload' as const,
      typeArguments: [
        
      ],
    },
  };
  const jsonPayload = JSON.stringify(initialValue, null, 2);

  const handleButton = () => {
    if (transactionHash) {
      setTransactionHash(null);
      return;
    }
    onSendTransaction(initialValue).then((hash) => {
      setTransactionHash(hash);
    }).catch((error) => {
      console.log(error);
    });
  };

  const showBackButton = !!transactionHash;

  return (
    <div className="send-transaction">
      <div> AddTrack </div>
      <div className="divider"/>
      {!transactionHash
        ? <div className='codeBlock'>
            <pre className='code'>
              {jsonPayload}
            </pre>
          </div>
        : <div className='send-transaction__hash'>
            <h5 className='send-transaction__title'>Success! Transaction hash:</h5>
            {transactionHash}
          </div>
      }
      <div className="divider"/>
      <button className="w-button send-transaction__button" onClick={handleButton}>{showBackButton ? 'Back' : 'Send'}</button>
    </div>
  );
};
