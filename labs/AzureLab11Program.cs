using Azure;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Models;
using System;
using System.Threading.Tasks;

namespace MessageProcessor
{
    public class Program
	{
		private const string storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=asyncstorcc;AccountKey=DMgp+uPyZS4yohDz8LNlWhYGdK1r68yUtas1+mkECRyn7MLC+dg5UvUVD/Hv2uGKPdwt1IXLdWg6YYO+3sxcpg==;EndpointSuffix=core.windows.net";
		private const string queueName = "messagequeue";

		public static async Task Main(string[] args)
		{
			Console.WriteLine("Hello MessageProcessor");
			
			QueueClient client = new QueueClient(storageConnectionString, queueName);        
			await client.CreateAsync();

			Console.WriteLine($"---Account Metadata---");
			Console.WriteLine($"Account Uri:\t{client.Uri}");
			//Console.WriteLine($"---Existing Messages---");
			int batchSize = 10;
			TimeSpan visibilityTimeout = TimeSpan.FromSeconds(2.5d);
			
			Response<QueueMessage[]> messages = await client.ReceiveMessagesAsync(batchSize, visibilityTimeout);
			Console.WriteLine($"type of <messages> is {messages.GetType()}");
			//**************************************************************************
			//if(messages?.MessageId? == null)	Console.WriteLine("\nno messages\n");
			if (messages.Value.ToString() == "Azure.Storage.Queues.Models.QueueMessage[]")
				Console.WriteLine("\npredicate is <<messages.Value.ToString()>>\n");
			if (messages.Value.Length == 0)
				Console.WriteLine("\nno messages\n");
			//**************************************************************************
			//foreach(QueueMessage message in messages?.Value)
				//Console.WriteLine($"[{message.MessageId}]\t{message.MessageText}");
			foreach(QueueMessage message in messages?.Value)
			{
				Console.WriteLine($"[{message.MessageId}]\t{message.MessageText}");
				await client.DeleteMessageAsync(message.MessageId, message.PopReceipt);
			}		
		}
	}
}
